require 'rails_helper'

RSpec.describe UserGroupPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:super_admin_user) { create(:user, :super_admin, organization: organization) }
  let(:group_admin) { create(:user, organization: organization) }
  let(:group_member) { create(:user, organization: organization) }
  let(:other_organization_user) { create(:user, organization: create(:organization)) }

  let(:user_group) { create(:user_group, organization: organization) }
  let(:other_organization_group) { create(:user_group, organization: other_organization_user.organization) }

  before do
    user_group.add_user(group_admin, role: 'admin')
    user_group.add_user(group_member, role: 'member')
  end

  subject { described_class }

  permissions ".scope" do
    it "returns groups where user is member for regular users" do
      user_group.add_user(user, role: 'member')
      other_group = create(:user_group, organization: organization)
      
      resolved_scope = subject::Scope.new(user, UserGroup.all).resolve
      expect(resolved_scope).to include(user_group)
      expect(resolved_scope).not_to include(other_group)
      expect(resolved_scope).not_to include(other_organization_group)
    end

    it "returns all groups in organization for admins" do
      other_group = create(:user_group, organization: organization)
      
      resolved_scope = subject::Scope.new(admin_user, UserGroup.all).resolve
      expect(resolved_scope).to include(user_group)
      expect(resolved_scope).to include(other_group)
      expect(resolved_scope).not_to include(other_organization_group)
    end

    it "returns all groups for super admins" do
      resolved_scope = subject::Scope.new(super_admin_user, UserGroup.all).resolve
      expect(resolved_scope).to include(user_group)
      expect(resolved_scope).to include(other_organization_group)
    end
  end

  permissions :index? do
    it "denies access to regular users" do
      expect(subject).not_to permit(user, UserGroup)
    end

    it "grants access to admins" do
      expect(subject).to permit(admin_user, UserGroup)
    end

    it "grants access to super admins" do
      expect(subject).to permit(super_admin_user, UserGroup)
    end
  end

  permissions :show? do
    it "denies regular users viewing groups they're not in" do
      expect(subject).not_to permit(user, user_group)
    end

    it "allows group members to view the group" do
      expect(subject).to permit(group_member, user_group)
    end

    it "allows group admins to view the group" do
      expect(subject).to permit(group_admin, user_group)
    end

    it "allows admins to view groups in their organization" do
      expect(subject).to permit(admin_user, user_group)
    end

    it "denies viewing groups from other organizations" do
      expect(subject).not_to permit(user, other_organization_group)
      expect(subject).not_to permit(admin_user, other_organization_group)
    end
  end

  permissions :create? do
    it "denies creation to regular users without permission" do
      expect(subject).not_to permit(user, UserGroup)
    end

    it "allows users with user_groups:create permission" do
      user.add_permission('user_groups:create')
      expect(subject).to permit(user, UserGroup)
    end

    it "allows admins to create groups" do
      expect(subject).to permit(admin_user, UserGroup)
    end

    it "allows super admins to create groups" do
      expect(subject).to permit(super_admin_user, UserGroup)
    end
  end

  permissions :update? do
    it "denies regular users updating groups" do
      expect(subject).not_to permit(user, user_group)
    end

    it "allows group admins to update the group" do
      expect(subject).to permit(group_admin, user_group)
    end

    it "allows users with user_groups:manage permission" do
      user.add_permission('user_groups:manage')
      expect(subject).to permit(user, user_group)
    end

    it "allows admins to update groups in their organization" do
      expect(subject).to permit(admin_user, user_group)
    end
  end

  permissions :destroy? do
    it "denies regular users destroying groups" do
      expect(subject).not_to permit(user, user_group)
    end

    it "denies group admins without permission" do
      expect(subject).not_to permit(group_admin, user_group)
    end

    it "allows group admins with user_groups:delete permission" do
      group_admin.add_permission('user_groups:delete')
      expect(subject).to permit(group_admin, user_group)
    end

    it "allows admins to destroy groups" do
      expect(subject).to permit(admin_user, user_group)
    end

    it "allows super admins to destroy groups" do
      expect(subject).to permit(super_admin_user, user_group)
    end
  end

  permissions :manage_members?, :add_member?, :remove_member? do
    it "follows update permissions" do
      expect(subject).not_to permit(user, user_group)
      expect(subject).to permit(group_admin, user_group)
      expect(subject).to permit(admin_user, user_group)
    end
  end

  permissions :leave_group? do
    it "allows members to leave if they're not admin" do
      expect(subject).to permit(group_member, user_group)
    end

    it "denies group admins from leaving" do
      expect(subject).not_to permit(group_admin, user_group)
    end

    it "denies users not in the group" do
      expect(subject).not_to permit(user, user_group)
    end
  end

  describe "#permitted_attributes" do
    let(:policy) { described_class.new(user, user_group) }
    
    it "returns the correct permitted attributes" do
      expect(policy.permitted_attributes).to contain_exactly(
        :name, :slug, :description, :group_type, :is_active, permissions: {}
      )
    end
    
    it "returns the same attributes for all users" do
      admin_policy = described_class.new(admin_user, user_group)
      super_admin_policy = described_class.new(super_admin_user, user_group)
      group_admin_policy = described_class.new(group_admin, user_group)
      
      expect(admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
      expect(super_admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
      expect(group_admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
    end
  end
end