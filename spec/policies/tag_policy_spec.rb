require 'rails_helper'

RSpec.describe TagPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:super_admin_user) { create(:user, :super_admin, organization: organization) }
  let(:tag_creator) { create(:user, organization: organization, permissions: { 'tag:create' => true }) }
  let(:tag_manager) { create(:user, organization: organization, permissions: { 'tag:manage' => true }) }
  let(:other_organization_user) { create(:user, organization: create(:organization)) }

  let(:tag) { create(:tag, organization: organization) }
  let(:other_organization_tag) { create(:tag, organization: other_organization_user.organization) }

  subject { described_class }

  permissions ".scope" do
    it "returns tags from user's organization" do
      other_tag = create(:tag, organization: organization)
      
      resolved_scope = subject::Scope.new(user, Tag.all).resolve
      expect(resolved_scope).to include(tag)
      expect(resolved_scope).to include(other_tag)
      expect(resolved_scope).not_to include(other_organization_tag)
    end
  end

  permissions :index? do
    it "grants access to all authenticated users" do
      expect(subject).to permit(user, Tag)
      expect(subject).to permit(admin_user, Tag)
      expect(subject).to permit(super_admin_user, Tag)
    end
  end

  permissions :show? do
    it "grants access to all authenticated users" do
      expect(subject).to permit(user, tag)
      expect(subject).to permit(admin_user, tag)
      expect(subject).to permit(super_admin_user, tag)
    end
  end

  permissions :create? do
    it "denies creation to regular users" do
      expect(subject).not_to permit(user, Tag)
    end

    it "allows users with tag:create permission" do
      expect(subject).to permit(tag_creator, Tag)
    end

    it "allows admins to create tags" do
      expect(subject).to permit(admin_user, Tag)
    end

    it "allows super admins to create tags" do
      expect(subject).to permit(super_admin_user, Tag)
    end
  end

  permissions :update? do
    it "denies update to regular users" do
      expect(subject).not_to permit(user, tag)
    end

    it "allows users with tag:manage permission" do
      expect(subject).to permit(tag_manager, tag)
    end

    it "allows admins to update tags" do
      expect(subject).to permit(admin_user, tag)
    end

    it "allows super admins to update tags" do
      expect(subject).to permit(super_admin_user, tag)
    end
  end

  permissions :destroy? do
    it "denies destroy to regular users" do
      expect(subject).not_to permit(user, tag)
    end

    it "allows users with tag:manage permission" do
      expect(subject).to permit(tag_manager, tag)
    end

    it "allows admins to destroy tags" do
      expect(subject).to permit(admin_user, tag)
    end

    it "allows super admins to destroy tags" do
      expect(subject).to permit(super_admin_user, tag)
    end
  end

  permissions :autocomplete? do
    it "grants access to all authenticated users" do
      expect(subject).to permit(user, Tag)
      expect(subject).to permit(admin_user, Tag)
      expect(subject).to permit(super_admin_user, Tag)
    end
  end

  describe "#permitted_attributes" do
    let(:policy) { described_class.new(user, tag) }
    
    it "returns the correct permitted attributes" do
      expect(policy.permitted_attributes).to contain_exactly(:name, :color)
    end
    
    it "returns the same attributes for all users" do
      admin_policy = described_class.new(admin_user, tag)
      super_admin_policy = described_class.new(super_admin_user, tag)
      tag_manager_policy = described_class.new(tag_manager, tag)
      
      expect(admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
      expect(super_admin_policy.permitted_attributes).to eq(policy.permitted_attributes)
      expect(tag_manager_policy.permitted_attributes).to eq(policy.permitted_attributes)
    end
  end
end