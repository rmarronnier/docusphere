require 'rails_helper'

RSpec.describe Authorizable, type: :concern do
  # Create a test class to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'documents' # Using documents table which should support authorizations
      include Authorizable
      
      def self.name
        'TestAuthorizable'
      end
    end
  end

  let(:authorizable_instance) { test_class.new }
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:user_group) { create(:user_group, organization: organization) }
  let(:super_admin) { create(:user, role: 'super_admin', organization: organization) }

  before do
    # Skip tests if the table doesn't exist
    skip "Tests require documents table" unless test_class.table_exists?
    
    authorizable_instance.save! if authorizable_instance.respond_to?(:save!)
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
      expect(test_class).to respond_to(:readable_by)
      expect(test_class).to respond_to(:writable_by)
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
      expect(auth.revocation_comment).to eq(comment)
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
      user_group.add_member(user)
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
      user_group.add_member(user)
      authorizable_instance.authorize_group(user_group, 'write', granted_by: other_user)
    end

    it 'returns combined permissions from user and groups' do
      permissions = authorizable_instance.permissions_for(user)
      expect(permissions).to include('read', 'write')
    end

    it 'returns unique permissions' do
      authorizable_instance.authorize_user(user, 'read', granted_by: other_user) # Duplicate
      permissions = authorizable_instance.permissions_for(user)
      expect(permissions.count('read')).to eq(1)
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
    let(:readable_item) { test_class.create! }
    let(:writable_item) { test_class.create! }
    let(:unreadable_item) { test_class.create! }

    before do
      readable_item.authorize_user(user, 'read', granted_by: other_user)
      writable_item.authorize_user(user, 'write', granted_by: other_user)
      # unreadable_item has no permissions for user
    end

    it 'readable_by scope returns items user can read' do
      readable_items = test_class.readable_by(user)
      expect(readable_items).to include(readable_item, writable_item)
      expect(readable_items).not_to include(unreadable_item)
    end

    it 'writable_by scope returns items user can write' do
      writable_items = test_class.writable_by(user)
      expect(writable_items).to include(writable_item)
      expect(writable_items).not_to include(readable_item, unreadable_item)
    end
  end

  describe 'private #owned_by?' do
    it 'returns true when object has user attribute matching the user' do
      if authorizable_instance.respond_to?(:user=)
        authorizable_instance.user = user
        expect(authorizable_instance.send(:owned_by?, user)).to be true
        expect(authorizable_instance.send(:owned_by?, other_user)).to be false
      end
    end

    it 'returns true when object has project_manager attribute matching the user' do
      if authorizable_instance.respond_to?(:project_manager=)
        authorizable_instance.project_manager = user
        expect(authorizable_instance.send(:owned_by?, user)).to be true
        expect(authorizable_instance.send(:owned_by?, other_user)).to be false
      end
    end

    it 'returns false when user is not the owner' do
      expect(authorizable_instance.send(:owned_by?, user)).to be false
    end
  end
end