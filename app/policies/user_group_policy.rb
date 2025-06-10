class UserGroupPolicy < ApplicationPolicy
  def index?
    user_is_admin?
  end

  def show?
    same_organization_or_admin? && (
      user_is_admin? || 
      user.member_of_group?(record) ||
      user.admin_of_group?(record)
    )
  end

  def create?
    user_is_admin? || user_has_permission?('user_groups:create')
  end

  def update?
    same_organization_or_admin? && (
      user_is_admin? || 
      user.admin_of_group?(record) ||
      user_has_permission?('user_groups:manage')
    )
  end

  def destroy?
    user_is_admin? || (
      same_organization? && 
      user.admin_of_group?(record) &&
      user_has_permission?('user_groups:delete')
    )
  end

  def manage_members?
    update?
  end
  
  def add_member?
    update?
  end
  
  def remove_member?
    update?
  end

  def leave_group?
    user.member_of_group?(record) && !user.admin_of_group?(record)
  end

  def permitted_attributes
    [:name, :slug, :description, :group_type, :is_active, permissions: {}]
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.admin?
        scope.where(organization: user.organization)
      else
        scope.joins(:user_group_memberships)
             .where(organization: user.organization)
             .where(user_group_memberships: { user: user })
             .distinct
      end
    end
  end
end