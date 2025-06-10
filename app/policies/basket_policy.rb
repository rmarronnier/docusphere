class BasketPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (basket_belongs_to_user? || basket_is_shared_and_active? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def create?
    user.present?
  end

  def update?
    user.present? && (basket_belongs_to_user? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def destroy?
    user.present? && (basket_belongs_to_user? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def share?
    user.present? && (basket_belongs_to_user? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def unshare?
    user.present? && (basket_belongs_to_user? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def add_item?
    user.present? && can_modify_basket?
  end

  def remove_item?
    user.present? && can_modify_basket?
  end

  def download?
    user.present? && (basket_belongs_to_user? || basket_is_shared_and_active? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def duplicate?
    user.present?
  end

  def clear?
    user.present? && (basket_belongs_to_user? || user_is_admin_in_same_org? || user.super_admin?)
  end

  def permitted_attributes
    [:name, :description, :basket_type, :is_shared, settings: {}]
  end

  class Scope < Scope
    def resolve
      if user.blank?
        scope.none
      elsif user&.super_admin?
        scope.all
      elsif user&.admin?
        # Admins can see all baskets in their organization
        scope.joins(:user).where(users: { organization: user.organization })
      else
        # Regular users can see their own baskets and shared baskets
        scope.where("baskets.user_id = ? OR baskets.is_shared = true", user.id)
      end
    end

    def shared_scope
      scope.where(is_shared: true)
    end

    def user_baskets_scope
      return scope.none unless user.present?
      scope.where(user: user)
    end
  end

  private

  def basket_belongs_to_user?
    record.user == user
  end

  def basket_is_shared_and_active?
    record.is_shared
  end

  def can_modify_basket?
    basket_belongs_to_user? || 
    basket_is_shared_and_active? ||
    user_is_admin_in_same_org? ||
    user.super_admin?
  end

  def user_is_admin_in_same_org?
    return false unless user&.organization && record.user&.organization
    (user.admin? || user.super_admin?) && user.organization == record.user.organization
  end

  def basket_owner_in_same_org?
    return false unless user&.organization && record.user&.organization
    user.organization == record.user.organization
  end
end