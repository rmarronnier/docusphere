class Immo::Promo::ProjectPolicy < ApplicationPolicy
  def index?
    # Only users from the same organization or with specific permissions
    user_is_admin? || user_has_permission?('immo_promo:access') || user_has_permission?('immo_promo:read')
  end

  def dashboard?
    # Only users from the same organization or with specific permissions
    user_is_admin? || user_has_permission?('immo_promo:access') || user_has_permission?('immo_promo:read')
  end

  def show?
    same_organization_or_admin? && (
      user_can_read?(record) ||
      user_has_permission?('immo_promo:read') || 
      user_has_permission?('immo_promo:access')
    )
  end

  def create?
    user_has_permission?('immo_promo:projects:create') || user_is_admin?
  end

  def update?
    return true if user_is_admin?
    same_organization? && (
      user_can_write?(record) ||
      user_has_permission?('immo_promo:projects:write') ||
      user_has_permission?('immo_promo:write')
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

  def manage_commercial?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:commercial:manage') ||
      record.project_manager == user ||
      user_has_permission?('immo_promo:sales:manage')
    )
  end

  def coordinate?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:coordination:manage') ||
      record.project_manager == user ||
      user_has_permission?('immo_promo:stakeholders:coordinate')
    )
  end

  def manage_finances?
    return true if user_is_admin?
    same_organization? && (
      user_has_permission?('immo_promo:financial:manage') ||
      record.project_manager == user ||
      user_has_permission?('immo_promo:budget:manage')
    )
  end

  # Document-related permissions
  def preview?
    show? # If user can see the project, they can preview documents
  end

  def share?
    update? # If user can update the project, they can share documents
  end

  def request_validation?
    update? # If user can update the project, they can request validation
  end

  def bulk_actions?
    update? # If user can update the project, they can perform bulk actions
  end

  def permitted_attributes
    base_attributes = [:name, :slug, :description, :reference_number, :project_type, 
                      :status, :address, :city, :postal_code, :country, :latitude, 
                      :longitude, :total_area, :land_area, :buildable_surface_area, 
                      :total_units, :start_date, :expected_completion_date, 
                      :building_permit_number, metadata: {}]
    
    if user_is_admin? || record.project_manager == user
      base_attributes + [:total_budget_cents, :current_budget_cents, :actual_end_date]
    else
      base_attributes
    end
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      elsif user.admin? || user.has_permission?('immo_promo:access')
        # Admins and users with immo_promo:access can see all projects in their organization
        scope.where(organization: user.organization)
      else
        # Other users can see projects where they have specific permissions OR are project manager
        projects_with_permissions = scope.joins(:authorizations)
                                        .where(organization: user.organization)
                                        .where(
                                          authorizations: {
                                            user: user,
                                            permission_level: [ 'read', 'write', 'admin' ]
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
