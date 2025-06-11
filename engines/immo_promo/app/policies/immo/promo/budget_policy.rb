class Immo::Promo::BudgetPolicy < ApplicationPolicy
  def index?
    # Can see budgets if can read the project
    project_policy.show?
  end

  def show?
    same_organization_or_admin? && (
      user_can_read?(record.project) ||
      user_has_permission?('immo_promo:budget:read') ||
      user_has_permission?('immo_promo:financial:read') ||
      user_has_permission?('immo_promo:access')
    )
  end

  def create?
    return true if user_is_admin?
    same_organization? && (
      user_can_write?(record.project) ||
      user_has_permission?('immo_promo:budget:create') ||
      user_has_permission?('immo_promo:budget:manage') ||
      record.project.project_manager == user
    )
  end

  def update?
    return true if user_is_admin?
    same_organization? && (
      user_can_write?(record.project) ||
      user_has_permission?('immo_promo:budget:write') ||
      user_has_permission?('immo_promo:budget:manage') ||
      record.project.project_manager == user
    )
  end

  def destroy?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:budget:delete') ||
      user_has_permission?('immo_promo:budget:manage') ||
      record.project.project_manager == user
    ) && record.can_be_deleted?
  end

  def approve?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:budget:approve') ||
      user_has_permission?('immo_promo:budget:manage') ||
      user_has_permission?('immo_promo:financial:approve') ||
      record.project.project_manager == user
    )
  end

  def reject?
    approve? # Same permissions as approve
  end

  def duplicate?
    create? # Same permissions as create since it creates a new budget
  end

  def permitted_attributes
    base_attributes = [:name, :description, :status, :budget_type, :fiscal_year, :version]

    if user_is_admin? || user_has_permission?('immo_promo:budget:manage') || record&.project&.project_manager == user
      base_attributes + [:total_amount_cents, :spent_amount_cents, :approved_date, :approved_by_id, :is_current]
    else
      base_attributes
    end
  end

  private

  def project_policy
    @project_policy ||= Immo::Promo::ProjectPolicy.new(user, record&.project || record)
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.admin? || user.has_permission?('immo_promo:access')
        # Admins and users with immo_promo:access can see all budgets in their organization
        scope.joins(:project).where(immo_promo_projects: { organization: user.organization })
      else
        # Other users can see budgets for projects they have access to
        accessible_project_ids = Immo::Promo::ProjectPolicy::Scope.new(user, Immo::Promo::Project).resolve.select(:id)
        scope.where(project_id: accessible_project_ids)
      end
    end
  end
end