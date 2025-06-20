require 'rails_helper'

RSpec.describe Authorizable, type: :concern do
  # Use Document model which already includes Authorizable
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:user_group) { create(:user_group, organization: organization) }
  let(:super_admin) { create(:user, role: 'super_admin', organization: organization) }
  let(:space) { create(:space, organization: organization) }
  
  # Create a Document instance to test the concern
  let(:third_user) { create(:user, organization: organization) }
  let(:authorizable_instance) { create(:document, space: space, uploaded_by: third_user) }

  before do
    # Ensure we have a clean state
    Authorization.destroy_all
  end

  describe 'included module behavior' do
    it 'adds authorizations association' do
      expect(authorizable_instance).to respond_to(:authorizations)
      expect(authorizable_instance).to respond_to(:active_authorizations)
    end

    it 'adds authorization methods' do
      expect(authorizable_instance).to respond_to(:authorize_user)
      expect(authorizable_instance).to respond_to(:authorize_group)
      expect(authorizable_instance).to respond_to(:revoke_authorization)
      expect(authorizable_instance).to respond_to(:readable_by?)
      expect(authorizable_instance).to respond_to(:writable_by?)
      expect(authorizable_instance).to respond_to(:admin_by?)
    end

    it 'adds scopes to the class' do
      expect(Document).to respond_to(:readable_by)
      expect(Document).to respond_to(:writable_by)
    end
  end

  describe '#authorize_user' do
    it 'creates a user authorization' do
      expect {
        authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      }.to change { authorizable_instance.authorizations.count }.by(1)
      
      auth = authorizable_instance.authorizations.last
      expect(auth.user).to eq(user)
      expect(auth.permission_level).to eq('read')
      expect(auth.granted_by).to eq(other_user)
    end

    it 'accepts optional parameters' do
      expires_at = 1.month.from_now
      comment = 'Test authorization'
      
      authorizable_instance.authorize_user(
        user, 'write', 
        granted_by: other_user, 
        expires_at: expires_at, 
        comment: comment
      )
      
      auth = authorizable_instance.authorizations.last
      expect(auth.expires_at).to be_within(1.second).of(expires_at)
      expect(auth.comment).to eq(comment)
    end
  end

  describe '#authorize_group' do
    it 'creates a group authorization' do
      expect {
        authorizable_instance.authorize_group(user_group, 'read', granted_by: user)
      }.to change { authorizable_instance.authorizations.count }.by(1)
      
      auth = authorizable_instance.authorizations.last
      expect(auth.user_group).to eq(user_group)
      expect(auth.permission_level).to eq('read')
      expect(auth.granted_by).to eq(user)
    end
  end

  describe '#revoke_authorization' do
    before do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
    end

    it 'revokes user authorization' do
      auth = authorizable_instance.active_authorizations.for_user(user).first
      expect(auth).to be_present
      expect(auth.revoked_at).to be_nil
      
      authorizable_instance.revoke_authorization(user, 'read', revoked_by: other_user)
      
      auth.reload
      expect(auth.revoked_at).to be_present
    end

    it 'accepts revocation comment' do
      comment = 'Access no longer needed'
      authorizable_instance.revoke_authorization(user, 'read', revoked_by: other_user, comment: comment)
      
      auth = authorizable_instance.authorizations.for_user(user).first
      expect(auth.comment).to include(comment)
    end
  end

  describe '#readable_by?' do
    it 'returns true for super admin' do
      expect(authorizable_instance.readable_by?(super_admin)).to be true
    end

    it 'returns true for owner when owned_by? is true' do
      allow(authorizable_instance).to receive(:owned_by?).with(user).and_return(true)
      expect(authorizable_instance.readable_by?(user)).to be true
    end

    it 'returns true for user with read permission' do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      expect(authorizable_instance.readable_by?(user)).to be true
    end

    it 'returns true for user with write permission' do
      authorizable_instance.authorize_user(user, 'write', granted_by: other_user)
      expect(authorizable_instance.readable_by?(user)).to be true
    end

    it 'returns true for user with admin permission' do
      authorizable_instance.authorize_user(user, 'admin', granted_by: other_user)
      expect(authorizable_instance.readable_by?(user)).to be true
    end

    it 'returns false for user without permission' do
      expect(authorizable_instance.readable_by?(user)).to be false
    end
  end

  describe '#writable_by?' do
    it 'returns true for super admin' do
      expect(authorizable_instance.writable_by?(super_admin)).to be true
    end

    it 'returns true for owner when owned_by? is true' do
      allow(authorizable_instance).to receive(:owned_by?).with(user).and_return(true)
      expect(authorizable_instance.writable_by?(user)).to be true
    end

    it 'returns false for user with only read permission' do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      expect(authorizable_instance.writable_by?(user)).to be false
    end

    it 'returns true for user with write permission' do
      authorizable_instance.authorize_user(user, 'write', granted_by: other_user)
      expect(authorizable_instance.writable_by?(user)).to be true
    end

    it 'returns true for user with admin permission' do
      authorizable_instance.authorize_user(user, 'admin', granted_by: other_user)
      expect(authorizable_instance.writable_by?(user)).to be true
    end
  end

  describe '#admin_by?' do
    it 'returns true for super admin' do
      expect(authorizable_instance.admin_by?(super_admin)).to be true
    end

    it 'returns true for owner when owned_by? is true' do
      allow(authorizable_instance).to receive(:owned_by?).with(user).and_return(true)
      expect(authorizable_instance.admin_by?(user)).to be true
    end

    it 'returns false for user with read or write permission' do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      expect(authorizable_instance.admin_by?(user)).to be false
      
      authorizable_instance.revoke_authorization(user, 'read', revoked_by: other_user)
      authorizable_instance.authorize_user(user, 'write', granted_by: other_user)
      expect(authorizable_instance.admin_by?(user)).to be false
    end

    it 'returns true for user with admin permission' do
      authorizable_instance.authorize_user(user, 'admin', granted_by: other_user)
      expect(authorizable_instance.admin_by?(user)).to be true
    end
  end

  describe '#can_validate?' do
    it 'returns true for super admin' do
      expect(authorizable_instance.can_validate?(super_admin)).to be true
    end

    it 'returns true for owner when owned_by? is true' do
      allow(authorizable_instance).to receive(:owned_by?).with(user).and_return(true)
      expect(authorizable_instance.can_validate?(user)).to be true
    end

    it 'returns true for user with validate permission' do
      authorizable_instance.authorize_user(user, 'validate', granted_by: other_user)
      expect(authorizable_instance.can_validate?(user)).to be true
    end

    it 'returns true for user with admin permission' do
      authorizable_instance.authorize_user(user, 'admin', granted_by: other_user)
      expect(authorizable_instance.can_validate?(user)).to be true
    end

    it 'returns false for user with only read permission' do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      expect(authorizable_instance.can_validate?(user)).to be false
    end
  end

  describe '#authorized_for?' do
    it 'returns false for nil user' do
      expect(authorizable_instance.authorized_for?(nil, 'read')).to be false
    end

    it 'checks direct user permissions' do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      expect(authorizable_instance.authorized_for?(user, 'read')).to be true
      expect(authorizable_instance.authorized_for?(user, 'write')).to be false
    end

    it 'checks group permissions' do
      user_group.add_user(user)
      authorizable_instance.authorize_group(user_group, 'write', granted_by: other_user)
      
      expect(authorizable_instance.authorized_for?(user, 'write')).to be true
      expect(authorizable_instance.authorized_for?(user, 'admin')).to be false
    end
  end

  describe '#grant_permission' do
    it 'grants permission to user' do
      expect {
        authorizable_instance.grant_permission(user, 'read', granted_by: other_user)
      }.to change { authorizable_instance.authorizations.count }.by(1)
    end

    it 'grants permission to group' do
      expect {
        authorizable_instance.grant_permission(user_group, 'read', granted_by: other_user)
      }.to change { authorizable_instance.authorizations.count }.by(1)
    end

    it 'raises error for invalid subject' do
      expect {
        authorizable_instance.grant_permission('invalid', 'read', granted_by: other_user)
      }.to raise_error(ArgumentError, 'Subject must be a User or UserGroup')
    end
  end

  describe '#revoke_permission' do
    before do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
    end

    it 'revokes permission from user' do
      auth = authorizable_instance.active_authorizations.for_user(user).first
      expect(auth.revoked_at).to be_nil
      
      authorizable_instance.revoke_permission(user, 'read', revoked_by: other_user)
      
      auth.reload
      expect(auth.revoked_at).to be_present
    end
  end

  describe '#permissions_for' do
    before do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      user_group.add_user(user)
      authorizable_instance.authorize_group(user_group, 'write', granted_by: other_user)
    end

    it 'returns combined permissions from user and groups' do
      permissions = authorizable_instance.permissions_for(user)
      expect(permissions).to include('read', 'write')
    end

    it 'returns unique permissions' do
      # The before block already created a 'read' permission
      # Try to create another 'read' permission through group
      another_group = create(:user_group, organization: organization)
      another_group.add_user(user)
      authorizable_instance.authorize_group(another_group, 'read', granted_by: other_user)
      
      permissions = authorizable_instance.permissions_for(user)
      # Should have 'read' only once despite having it from both user and group
      expect(permissions.count('read')).to eq(1)
      expect(permissions).to include('read', 'write')
    end
  end

  describe '#authorized_users' do
    before do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
      authorizable_instance.authorize_user(other_user, 'write', granted_by: user)
    end

    it 'returns all authorized users when no permission specified' do
      users = authorizable_instance.authorized_users
      expect(users).to include(user, other_user)
    end

    it 'filters by permission level' do
      read_users = authorizable_instance.authorized_users('read')
      expect(read_users).to include(user)
      expect(read_users).not_to include(other_user)
    end
  end

  describe '#authorized_groups' do
    let(:other_group) { create(:user_group, organization: organization) }

    before do
      authorizable_instance.authorize_group(user_group, 'read', granted_by: user)
      authorizable_instance.authorize_group(other_group, 'write', granted_by: user)
    end

    it 'returns all authorized groups when no permission specified' do
      groups = authorizable_instance.authorized_groups
      expect(groups).to include(user_group, other_group)
    end

    it 'filters by permission level' do
      read_groups = authorizable_instance.authorized_groups('read')
      expect(read_groups).to include(user_group)
      expect(read_groups).not_to include(other_group)
    end
  end

  describe 'alias methods' do
    before do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user)
    end

    it 'provides alias methods for permission checks' do
      expect(authorizable_instance.can_read?(user)).to eq(authorizable_instance.readable_by?(user))
      expect(authorizable_instance.can_write?(user)).to eq(authorizable_instance.writable_by?(user))
      expect(authorizable_instance.can_admin?(user)).to eq(authorizable_instance.admin_by?(user))
    end
  end

  describe 'scope methods' do
    let(:readable_item) { create(:document, space: space, uploaded_by: third_user) }
    let(:writable_item) { create(:document, space: space, uploaded_by: third_user) }
    let(:unreadable_item) { create(:document, space: space, uploaded_by: third_user) }

    before do
      readable_item.authorize_user(user, 'read', granted_by: other_user)
      writable_item.authorize_user(user, 'write', granted_by: other_user)
      # unreadable_item has no permissions for user
    end

    it 'readable_by scope filters documents by read permission' do
      # Test that user can read readable_item
      expect(readable_item.readable_by?(user)).to be true
      expect(writable_item.readable_by?(user)).to be true  # write includes read
      expect(unreadable_item.readable_by?(user)).to be false
      
      # Test the scope
      readable_documents = Document.readable_by(user)
      expect(readable_documents).to include(readable_item, writable_item)
      expect(readable_documents).not_to include(unreadable_item)
    end

    it 'writable_by scope filters documents by write permission' do
      # Test that user can write to writable_item only
      expect(readable_item.writable_by?(user)).to be false
      expect(writable_item.writable_by?(user)).to be true
      expect(unreadable_item.writable_by?(user)).to be false
      
      # Test the scope
      writable_documents = Document.writable_by(user)
      expect(writable_documents).to include(writable_item)
      expect(writable_documents).not_to include(readable_item, unreadable_item)
    end
  end

  describe '#owned_by?' do
    context 'with Document' do
      let(:document) { create(:document, space: space, uploaded_by: user) }
      
      it 'returns true when user is the uploader' do
        expect(document.owned_by?(user)).to be true
        expect(document.owned_by?(other_user)).to be false
      end
    end

    context 'with Space' do
      let(:space_instance) { create(:space, organization: organization) }
      
      it 'returns false for all users (no ownership)' do
        expect(space_instance.owned_by?(user)).to be false
        expect(space_instance.owned_by?(other_user)).to be false
      end
    end

    context 'with Folder' do
      let(:folder) { create(:folder, space: space) }
      
      it 'returns false for all users (no ownership)' do
        expect(folder.owned_by?(user)).to be false
        expect(folder.owned_by?(other_user)).to be false
      end
    end

    it 'returns false when user is nil' do
      expect(authorizable_instance.owned_by?(nil)).to be false
    end
  end
end