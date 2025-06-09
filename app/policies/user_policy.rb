class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.super_admin?
  end

  def show?
    user.admin? || user.super_admin? || record == user
  end

  def create?
    user.admin? || user.super_admin?
  end

  def update?
    user.admin? || user.super_admin? || record == user
  end

  def destroy?
    (user.admin? || user.super_admin?) && record != user
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