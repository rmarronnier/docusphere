require 'rails_helper'

RSpec.describe Authorization, type: :model do
  let(:user) { create(:user) }
  let(:user_group) { create(:user_group, organization: user.organization) }
  let(:document) { create(:document, uploaded_by: user) }
  let(:granted_by) { create(:user, :admin, organization: user.organization) }
  
  describe 'validations' do
    it 'validates presence of permission_level' do
      authorization = build(:authorization, permission_level: nil)
      expect(authorization).not_to be_valid
      expect(authorization.errors[:permission_level]).to include("ne peut pas être vide")
    end
    
    it 'validates inclusion of permission_level' do
      authorization = build(:authorization, permission_level: 'invalid')
      expect(authorization).not_to be_valid
    end
    
    it 'requires either user or user_group' do
      authorization = build(:authorization, user: nil, user_group: nil)
      expect(authorization).not_to be_valid
      expect(authorization.errors[:base]).to include('User or UserGroup must be present')
    end
    
    it 'validates uniqueness of user_id scoped to authorizable and permission' do
      create(:authorization, user: user, authorizable: document, permission_level: 'read')
      duplicate = build(:authorization, user: user, authorizable: document, permission_level: 'read')
      expect(duplicate).not_to be_valid
    end
    
    it 'validates expiry date in future' do
      authorization = build(:authorization, expires_at: 1.day.ago)
      expect(authorization).not_to be_valid
      expect(authorization.errors[:expires_at]).to include('must be in the future')
    end
  end
  
  describe 'associations' do
    it { should belong_to(:authorizable) }
    it { should belong_to(:user).optional }
    it { should belong_to(:user_group).optional }
    it { should belong_to(:granted_by).optional }
    it { should belong_to(:revoked_by).optional }
  end
  
  describe 'scopes' do
    let!(:user_auth) { create(:authorization, user: user) }
    let!(:group_auth) { create(:authorization, :for_group, user_group: user_group) }
    let!(:expired_auth) { create(:authorization, :expired) }
    let!(:revoked_auth) { create(:authorization, :revoked) }
    
    it 'filters by user' do
      expect(Authorization.for_user(user)).to include(user_auth)
      expect(Authorization.for_user(user)).not_to include(group_auth)
    end
    
    it 'filters by group' do
      expect(Authorization.for_group(user_group)).to include(group_auth)
      expect(Authorization.for_group(user_group)).not_to include(user_auth)
    end
    
    it 'filters active authorizations' do
      active_auth = create(:authorization, user: user)
      expect(Authorization.active).to include(active_auth)
      expect(Authorization.active).not_to include(expired_auth)
      expect(Authorization.active).not_to include(revoked_auth)
    end
  end
  
  describe '#active?' do
    it 'returns true for non-expired, non-revoked authorization' do
      auth = create(:authorization)
      expect(auth).to be_active
    end
    
    it 'returns false for expired authorization' do
      auth = create(:authorization, expires_at: 1.day.from_now)
      auth.update_column(:expires_at, 1.day.ago)  # Bypass validation for testing
      expect(auth.reload).not_to be_active
    end
    
    it 'returns false for revoked authorization' do
      auth = create(:authorization)
      auth.revoke!(create(:user, :admin), comment: 'Test revocation')
      expect(auth.reload).not_to be_active
    end
  end
  
  describe '#revoke!' do
    let(:authorization) { create(:authorization, user: user) }
    let(:revoker) { create(:user, :admin) }
    
    it 'marks authorization as revoked' do
      authorization.revoke!(revoker, comment: 'Test revocation')
      
      expect(authorization.reload).to be_revoked
      expect(authorization.revoked_by).to eq(revoker)
      expect(authorization.comment).to include('Test revocation')
    end
  end
  
  describe '#extend_expiry!' do
    let(:authorization) { create(:authorization, expires_at: 1.week.from_now) }
    let(:extender) { create(:user, :admin) }
    
    it 'extends the expiry date' do
      new_expiry = 1.month.from_now
      authorization.extend_expiry!(new_expiry, extender, comment: 'Extended')
      
      expect(authorization.reload.expires_at).to be_within(1.second).of(new_expiry)
      expect(authorization.comment).to include('Extended')
    end
  end
end
