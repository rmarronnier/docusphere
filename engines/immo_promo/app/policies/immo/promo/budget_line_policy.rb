class Immo::Promo::BudgetLinePolicy < ApplicationPolicy
  def index?
    # Can see budget lines if can read the budget project
    budget_policy.show?
  end

  def show?
    same_organization_or_admin? && (
      user_can_read?(record.budget.project) ||
      user_has_permission?('immo_promo:budget:read') ||
      user_has_permission?('immo_promo:financial:read') ||
      user_has_permission?('immo_promo:access')
    )
  end

  def create?
    return true if user_is_admin?
    same_organization? && (
      user_can_write?(record.budget.project) ||
      user_has_permission?('immo_promo:budget:write') ||
      user_has_permission?('immo_promo:budget:manage') ||
      record.budget.project.project_manager == user
    )
  end

  def update?
    create? # Same permissions as create
  end

  def destroy?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:budget:delete') ||
      user_has_permission?('immo_promo:budget:manage') ||
      record.budget.project.project_manager == user
    ) && record.can_be_deleted?
  end

  def permitted_attributes
    base_attributes = [:category, :subcategory, :description, :notes]

    if user_is_admin? || user_has_permission?('immo_promo:budget:manage') || record&.budget&.project&.project_manager == user
      base_attributes + [:planned_amount_cents, :actual_amount_cents, :committed_amount_cents]
    else
      base_attributes
    end
  end

  private

  def budget_policy
    @budget_policy ||= Immo::Promo::BudgetPolicy.new(user, record&.budget || record)
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.admin? || user.has_permission?('immo_promo:access')
        # Admins and users with immo_promo:access can see all budget lines in their organization
        scope.joins(budget: :project).where(immo_promo_projects: { organization: user.organization })
      else
        # Other users can see budget lines for projects they have access to
        accessible_project_ids = Immo::Promo::ProjectPolicy::Scope.new(user, Immo::Promo::Project).resolve.select(:id)
        scope.joins(budget: :project).where(immo_promo_projects: { id: accessible_project_ids })
      end
    end
  end
end