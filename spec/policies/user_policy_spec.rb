require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:super_admin_user) { create(:user, :super_admin, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:other_organization_user) { create(:user, organization: create(:organization)) }

  subject { described_class }

  permissions ".scope" do
    it "returns only themselves for regular users" do
      resolved_scope = subject::Scope.new(user, User.all).resolve
      expect(resolved_scope).to include(user)
      expect(resolved_scope).not_to include(other_user)
      expect(resolved_scope).not_to include(other_organization_user)
    end

    it "returns users in same organization for admins" do
      resolved_scope = subject::Scope.new(admin_user, User.all).resolve
      expect(resolved_scope).to include(user)
      expect(resolved_scope).to include(admin_user)
      expect(resolved_scope).to include(other_user)
      expect(resolved_scope).not_to include(other_organization_user)
    end

    it "returns all users for super admins" do
      resolved_scope = subject::Scope.new(super_admin_user, User.all).resolve
      expect(resolved_scope).to include(user)
      expect(resolved_scope).to include(admin_user)
      expect(resolved_scope).to include(other_user)
      expect(resolved_scope).to include(other_organization_user)
    end
  end

  permissions :index? do
    it "denies access to regular users" do
      expect(subject).not_to permit(user, User)
    end

    it "grants access to admins" do
      expect(subject).to permit(admin_user, User)
    end

    it "grants access to super admins" do
      expect(subject).to permit(super_admin_user, User)
    end
  end

  permissions :show? do
    it "allows users to view themselves" do
      expect(subject).to permit(user, user)
    end

    it "denies users viewing others" do
      expect(subject).not_to permit(user, other_user)
    end

    it "allows admins to view users in their organization" do
      expect(subject).to permit(admin_user, user)
      expect(subject).to permit(admin_user, other_user)
    end

    it "denies admins viewing users from other organizations" do
      expect(subject).not_to permit(admin_user, other_organization_user)
    end

    it "allows super admins to view any user" do
      expect(subject).to permit(super_admin_user, user)
      expect(subject).to permit(super_admin_user, other_organization_user)
    end
  end

  permissions :create? do
    it "denies creation to regular users" do
      expect(subject).not_to permit(user, User)
    end

    it "allows admins to create users" do
      expect(subject).to permit(admin_user, User)
    end

    it "allows super admins to create users" do
      expect(subject).to permit(super_admin_user, User)
    end
  end

  permissions :update? do
    it "allows users to update themselves" do
      expect(subject).to permit(user, user)
    end

    it "denies users updating others" do
      expect(subject).not_to permit(user, other_user)
    end

    it "allows admins to update users in their organization" do
      expect(subject).to permit(admin_user, user)
      expect(subject).to permit(admin_user, other_user)
    end

    it "denies admins updating users from other organizations" do
      expect(subject).not_to permit(admin_user, other_organization_user)
    end

    it "allows super admins to update any user" do
      expect(subject).to permit(super_admin_user, user)
      expect(subject).to permit(super_admin_user, other_organization_user)
    end
  end

  permissions :destroy? do
    it "denies users destroying themselves" do
      expect(subject).not_to permit(user, user)
    end

    it "denies users destroying others" do
      expect(subject).not_to permit(user, other_user)
    end

    it "allows admins to destroy users in their organization except themselves" do
      expect(subject).to permit(admin_user, user)
      expect(subject).to permit(admin_user, other_user)
      expect(subject).not_to permit(admin_user, admin_user)
    end

    it "denies admins destroying users from other organizations" do
      expect(subject).not_to permit(admin_user, other_organization_user)
    end

    it "allows super admins to destroy any user except themselves" do
      expect(subject).to permit(super_admin_user, user)
      expect(subject).to permit(super_admin_user, other_organization_user)
      expect(subject).not_to permit(super_admin_user, super_admin_user)
    end
  end

  describe "#permitted_attributes" do
    it "returns full attributes for super admins" do
      policy = described_class.new(super_admin_user, user)
      expect(policy.permitted_attributes).to contain_exactly(
        :email, :first_name, :last_name, :role, :password, 
        :password_confirmation, :organization_id, permissions: {}
      )
    end

    it "returns attributes without organization_id for admins" do
      policy = described_class.new(admin_user, user)
      expect(policy.permitted_attributes).to contain_exactly(
        :email, :first_name, :last_name, :role, :password, 
        :password_confirmation, permissions: {}
      )
    end

    it "returns limited attributes for users updating themselves" do
      policy = described_class.new(user, user)
      expect(policy.permitted_attributes).to contain_exactly(
        :first_name, :last_name, :password, :password_confirmation
      )
    end

    it "returns empty array for users updating others" do
      policy = described_class.new(user, other_user)
      expect(policy.permitted_attributes).to eq([])
    end
  end
end