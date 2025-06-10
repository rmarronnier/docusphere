class FolderPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (same_organization_or_admin? || folder_accessible?)
  end

  def create?
    user.present? && (same_organization_or_admin? || can_write_in_space?)
  end

  def update?
    user.present? && (same_organization_or_admin? || folder_writable?)
  end

  def destroy?
    user.present? && (same_organization_or_admin? || folder_writable?)
  end

  def permitted_attributes
    [:name, :description, :slug, :position, :is_active, metadata: {}]
  end

  class Scope < Scope
    def resolve
      if user.blank?
        scope.none
      elsif user.super_admin?
        scope.all
      else
        scope.joins(:space).where(spaces: { organization: user.organization })
      end
    end
  end

  private

  def folder_accessible?
    return false unless record.space
    record.space.organization == user.organization
  end

  def folder_writable?
    return false unless record.space
    record.space.organization == user.organization
  end

  def can_write_in_space?
    return false unless record.space
    record.space.organization == user.organization
  end
end