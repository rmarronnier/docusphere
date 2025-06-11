class Immo::Promo::ApplicationPolicy < ApplicationPolicy
  def access?
    user&.admin? ||
    user&.super_admin? ||
    user&.has_permission?('immo_promo:access')
  end

  # For consistency with other policies
  def index?
    access?
  end

  def show?
    access?
  end

  def create?
    access?
  end

  def update?
    access?
  end

  def destroy?
    access?
  end

  class Scope < Scope
    def resolve
      if user&.super_admin? || user&.admin? || user&.has_permission?('immo_promo:access')
        scope.all
      else
        scope.none
      end
    end
  end
end