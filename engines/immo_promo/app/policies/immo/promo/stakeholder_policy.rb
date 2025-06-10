class Immo::Promo::StakeholderPolicy < ApplicationPolicy
  def index?
    Immo::Promo::ProjectPolicy.new(user, record.project).show?
  end

  def show?
    Immo::Promo::ProjectPolicy.new(user, record.project).show?
  end

  def create?
    Immo::Promo::ProjectPolicy.new(user, record.project).manage_stakeholders?
  end

  def update?
    Immo::Promo::ProjectPolicy.new(user, record.project).manage_stakeholders?
  end

  def destroy?
    return false if record.contracts.where(status: 'active').exists?
    Immo::Promo::ProjectPolicy.new(user, record.project).manage_stakeholders?
  end

  def manage_certifications?
    return true if user_is_admin?
    return true if record.project.project_manager_id == user.id

    user.organization_id == record.project.organization_id &&
    user_has_permission?('immo_promo:legal:manage')
  end

  def manage_contracts?
    return true if user_is_admin?
    return true if record.project.project_manager_id == user.id

    user.organization_id == record.project.organization_id &&
    user_has_permission?('immo_promo:contracts:manage')
  end

  def allocate?
    return true if user_is_admin?
    return true if record.project.project_manager_id == user.id

    user.organization_id == record.project.organization_id &&
    user_has_permission?('immo_promo:projects:manage')
  end

  def qualify?
    allocate? # Same permissions as allocation
  end

  def permitted_attributes
    [:name, :stakeholder_type, :contact_person, :email, :phone, :address, 
     :notes, :specialization, :is_active, :role, :company_name, :siret, 
     :is_primary]
  end

  class Scope < Scope
    def resolve
      project_scope = Pundit.policy_scope(user, Immo::Promo::Project)
      scope.joins(:project).where(project: project_scope)
    end
  end
end
