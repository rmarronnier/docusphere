class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.super_admin?
  end

  def show?
    return true if user.super_admin? || record == user
    return false unless user.admin?
    
    # Admin can only view users in their organization
    record.organization_id == user.organization_id
  end

  def create?
    user.admin? || user.super_admin?
  end

  def update?
    return true if user.super_admin? || record == user
    return false unless user.admin?
    
    # Admin can only update users in their organization
    record.organization_id == user.organization_id
  end

  def destroy?
    return false if record == user # Can't delete yourself
    return true if user.super_admin?
    return false unless user.admin?
    
    # Admin can only delete users in their organization
    record.organization_id == user.organization_id
  end

  def permitted_attributes
    if user.super_admin?
      [:email, :first_name, :last_name, :role, :password, :password_confirmation, :organization_id, permissions: {}]
    elsif user.admin?
      [:email, :first_name, :last_name, :role, :password, :password_confirmation, permissions: {}]
    elsif record == user
      [:first_name, :last_name, :password, :password_confirmation]
    else
      []
    end
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.admin?
        scope.where(organization: user.organization)
      else
        scope.where(id: user.id)
      end
    end
  end
end