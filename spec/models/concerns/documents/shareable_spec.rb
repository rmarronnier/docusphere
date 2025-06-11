require 'rails_helper'

RSpec.describe Documents::Shareable do
  let(:document) { create(:document) }
  let(:user) { create(:user) }
  let(:sharer) { create(:user) }

  describe 'associations' do
    # Note: association tests require the model class, not the concern module
    # These associations are tested in document_spec.rb
  end

  describe '#shared_with?' do
    it 'returns false when user is nil' do
      expect(document.shared_with?(nil)).to be false
    end
    
    it 'returns false when document is not shared with user' do
      expect(document.shared_with?(user)).to be false
    end
    
    it 'returns true when document is actively shared with user' do
      create(:document_share, document: document, shared_with: user, is_active: true)
      expect(document.shared_with?(user)).to be true
    end
    
    it 'returns false when share is not active' do
      create(:document_share, document: document, shared_with: user, is_active: false)
      expect(document.shared_with?(user)).to be false
    end
  end

  describe '#share_with!' do
    before do
      Current.user = sharer
    end
    
    after do
      Current.user = nil
    end
    
    it 'creates a new document share with default access level' do
      expect {
        document.share_with!(user)
      }.to change { document.document_shares.count }.by(1)
      
      share = document.document_shares.last
      expect(share.shared_with).to eq(user)
      expect(share.shared_by).to eq(sharer)
      expect(share.access_level).to eq('read')
      expect(share.expires_at).to be_nil
    end
    
    it 'creates a share with custom access level' do
      document.share_with!(user, access_level: 'write')
      
      share = document.document_shares.last
      expect(share.access_level).to eq('write')
    end
    
    it 'creates a share with expiration date' do
      expires_at = 1.week.from_now
      document.share_with!(user, expires_at: expires_at)
      
      share = document.document_shares.last
      expect(share.expires_at).to be_within(1.second).of(expires_at)
    end
    
    it 'allows specifying the sharer' do
      another_sharer = create(:user)
      document.share_with!(user, shared_by: another_sharer)
      
      share = document.document_shares.last
      expect(share.shared_by).to eq(another_sharer)
    end
  end
end