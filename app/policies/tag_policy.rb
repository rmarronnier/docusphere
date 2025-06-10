class TagPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.admin? || user.super_admin? || user.has_permission?('tag:create')
  end

  def update?
    user.admin? || user.super_admin? || user.has_permission?('tag:manage')
  end

  def destroy?
    user.admin? || user.super_admin? || user.has_permission?('tag:manage')
  end

  def autocomplete?
    true
  end

  def permitted_attributes
    [:name, :color]
  end

  class Scope < Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end