class Immo::Promo::ProjectPolicy < ApplicationPolicy
  def index?
    true # All authenticated users can see the project list (filtered by scope)
  end

  def dashboard?
    true # All authenticated users can see the dashboard (filtered by scope)
  end

  def show?
    same_organization_or_admin? && user_can_read?(record)
  end

  def create?
    user_has_permission?('immo_promo:projects:create') || user_is_admin?
  end

  def update?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:projects:write') ||
      record.project_manager == user ||
      user_can_write?(record)
    )
  end

  def destroy?
    user_is_admin? || (
      same_organization? && 
      user_has_permission?('immo_promo:projects:delete') &&
      record.project_manager == user
    )
  end

  def manage_stakeholders?
    update? || user_has_permission?('immo_promo:stakeholders:manage')
  end

  def manage_budget?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:budget:manage') ||
      record.project_manager == user
    )
  end

  def manage_permits?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:permits:manage') ||
      record.project_manager == user ||
      user_has_permission?('immo_promo:legal:manage')
    )
  end

  def view_financial_data?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:financial:read') ||
      record.project_manager == user
    )
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.admin?
        scope.where(organization: user.organization)
      else
        # Users can see projects where they have read permissions OR are project manager
        projects_with_permissions = scope.joins(:authorizations)
                                        .where(organization: user.organization)
                                        .where(
                                          authorizations: { 
                                            user: user, 
                                            permission_type: ['read', 'write', 'admin'] 
                                          }
                                        )
        
        projects_as_manager = scope.where(
          organization: user.organization, 
          project_manager: user
        )
        
        scope.where(id: projects_with_permissions.select(:id))
             .or(scope.where(id: projects_as_manager.select(:id)))
             .distinct
      end
    end
  end
end