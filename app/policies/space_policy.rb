class SpacePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && same_organization_or_admin?
  end

  def create?
    user.present? && same_organization_or_admin?
  end

  def update?
    user.present? && same_organization_or_admin?
  end

  def destroy?
    user.present? && same_organization_or_admin?
  end

  def permitted_attributes
    [:name, :slug, :description, :is_active, settings: {}]
  end

  class Scope < Scope
    def resolve
      if user.blank?
        scope.none
      elsif user.super_admin?
        scope.all
      else
        scope.where(organization: user.organization)
      end
    end
  end
end