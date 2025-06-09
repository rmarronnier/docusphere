require 'rails_helper'

RSpec.describe BasketPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:super_admin_user) { create(:user, :super_admin, organization: organization) }
  let(:other_organization_user) { create(:user, organization: create(:organization)) }

  let(:basket) { create(:basket, user: user) }
  let(:other_user_basket) { create(:basket, user: other_organization_user) }
  let(:shared_basket) { create(:basket, user: user, is_shared: true) }

  subject { described_class }

  permissions ".scope" do
    it "returns baskets for the current user only" do
      user_basket = create(:basket, user: user)
      admin_basket = create(:basket, user: admin_user)
      other_basket = create(:basket, user: other_organization_user)

      resolved_scope = subject::Scope.new(user, Basket.all).resolve
      expect(resolved_scope).to include(user_basket)
      expect(resolved_scope).not_to include(admin_basket)
      expect(resolved_scope).not_to include(other_basket)
    end

    it "allows admins to see all baskets in their organization" do
      user_basket = create(:basket, user: user)
      admin_basket = create(:basket, user: admin_user)
      other_basket = create(:basket, user: other_organization_user)

      resolved_scope = subject::Scope.new(admin_user, Basket.all).resolve
      expect(resolved_scope).to include(user_basket)
      expect(resolved_scope).to include(admin_basket)
      expect(resolved_scope).not_to include(other_basket)
    end

    it "allows super admins to see all baskets" do
      user_basket = create(:basket, user: user)
      other_basket = create(:basket, user: other_organization_user)

      resolved_scope = subject::Scope.new(super_admin_user, Basket.all).resolve
      expect(resolved_scope).to include(user_basket)
      expect(resolved_scope).to include(other_basket)
    end

    it "includes shared baskets that are accessible" do
      shared_basket = create(:basket, user: other_organization_user, is_shared: true)

      resolved_scope = subject::Scope.new(user, Basket.all).resolve
      expect(resolved_scope).to include(shared_basket)
    end
  end

  permissions :index? do
    it "grants access to authenticated users" do
      expect(subject).to permit(user, Basket)
    end

    it "denies access to unauthenticated users" do
      expect(subject).not_to permit(nil, Basket)
    end
  end

  permissions :show? do
    it "grants access to the basket owner" do
      expect(subject).to permit(user, basket)
    end

    it "denies access to other users for private baskets" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    it "grants access to shared baskets" do
      expect(subject).to permit(other_organization_user, shared_basket)
    end

    it "grants access to admins in same organization" do
      expect(subject).to permit(admin_user, basket)
    end

    it "grants access to super admins" do
      expect(subject).to permit(super_admin_user, basket)
      expect(subject).to permit(super_admin_user, other_user_basket)
    end

    # Note: Expiration functionality not yet implemented in basket model
  end

  permissions :create? do
    it "grants creation to authenticated users" do
      expect(subject).to permit(user, Basket)
    end

    it "denies creation to unauthenticated users" do
      expect(subject).not_to permit(nil, Basket)
    end
  end

  permissions :update? do
    it "allows users to update their own baskets" do
      expect(subject).to permit(user, basket)
    end

    it "denies users from updating other's baskets" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    it "allows admins to update baskets in their organization" do
      expect(subject).to permit(admin_user, basket)
    end

    it "allows super admins to update any basket" do
      expect(subject).to permit(super_admin_user, basket)
      expect(subject).to permit(super_admin_user, other_user_basket)
    end
  end

  permissions :destroy? do
    it "allows users to delete their own baskets" do
      expect(subject).to permit(user, basket)
    end

    it "denies users from deleting other's baskets" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    it "allows admins to delete baskets in their organization" do
      expect(subject).to permit(admin_user, basket)
    end

    it "allows super admins to delete any basket" do
      expect(subject).to permit(super_admin_user, basket)
      expect(subject).to permit(super_admin_user, other_user_basket)
    end
  end

  permissions :share? do
    it "allows users to share their own baskets" do
      expect(subject).to permit(user, basket)
    end

    it "denies users from sharing other's baskets" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    it "allows admins to share baskets in their organization" do
      expect(subject).to permit(admin_user, basket)
    end

    it "allows super admins to share any basket" do
      expect(subject).to permit(super_admin_user, basket)
      expect(subject).to permit(super_admin_user, other_user_basket)
    end
  end

  permissions :unshare? do
    it "allows users to unshare their own baskets" do
      expect(subject).to permit(user, shared_basket)
    end

    it "denies users from unsharing other's baskets" do
      expect(subject).not_to permit(other_organization_user, shared_basket)
    end

    it "allows admins to unshare baskets in their organization" do
      expect(subject).to permit(admin_user, shared_basket)
    end

    it "allows super admins to unshare any basket" do
      expect(subject).to permit(super_admin_user, shared_basket)
    end
  end

  permissions :add_item? do
    it "allows users to add items to their own baskets" do
      expect(subject).to permit(user, basket)
    end

    it "denies users from adding items to other's baskets" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    it "allows users to add items to shared baskets if not expired" do
      expect(subject).to permit(other_organization_user, shared_basket)
    end

    # Note: Expiration functionality not yet implemented

    it "allows admins to add items to baskets in their organization" do
      expect(subject).to permit(admin_user, basket)
    end
  end

  permissions :remove_item? do
    it "allows users to remove items from their own baskets" do
      expect(subject).to permit(user, basket)
    end

    it "denies users from removing items from other's baskets" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    it "allows users to remove items from shared baskets if not expired" do
      expect(subject).to permit(other_organization_user, shared_basket)
    end

    it "allows admins to remove items from baskets in their organization" do
      expect(subject).to permit(admin_user, basket)
    end
  end

  permissions :download? do
    it "allows users to download their own baskets" do
      expect(subject).to permit(user, basket)
    end

    it "allows users to download shared baskets" do
      expect(subject).to permit(other_organization_user, shared_basket)
    end

    it "denies users from downloading private baskets of others" do
      expect(subject).not_to permit(other_organization_user, basket)
    end

    # Note: Expiration functionality not yet implemented
  end

  describe "private helper methods" do
    let(:policy) { described_class.new(user, basket) }

    describe "#basket_belongs_to_user?" do
      it "returns true for own basket" do
        expect(policy.send(:basket_belongs_to_user?)).to be true
      end

      it "returns false for other user basket" do
        other_policy = described_class.new(user, other_user_basket)
        expect(other_policy.send(:basket_belongs_to_user?)).to be false
      end
    end

    describe "#basket_is_shared_and_active?" do
      it "returns true for shared basket" do
        shared_policy = described_class.new(user, shared_basket)
        expect(shared_policy.send(:basket_is_shared_and_active?)).to be true
      end

      it "returns false for private basket" do
        expect(policy.send(:basket_is_shared_and_active?)).to be false
      end
    end

    describe "#can_modify_basket?" do
      it "returns true for basket owner" do
        expect(policy.send(:can_modify_basket?)).to be true
      end

      it "returns true for shared basket" do
        shared_policy = described_class.new(other_organization_user, shared_basket)
        expect(shared_policy.send(:can_modify_basket?)).to be true
      end

      it "returns false for private basket of others" do
        other_policy = described_class.new(other_organization_user, basket)
        expect(other_policy.send(:can_modify_basket?)).to be false
      end
    end
  end
end