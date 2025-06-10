class Immo::Promo::TaskPolicy < ApplicationPolicy
  def index?
    Immo::Promo::PhasePolicy.new(user, record.phase).show?
  end

  def show?
    return true if record.assigned_to == user
    Immo::Promo::PhasePolicy.new(user, record.phase).show?
  end

  def create?
    return true if record.assigned_to == user
    Immo::Promo::PhasePolicy.new(user, record.phase).update?
  end

  def update?
    return true if user_is_admin?
    return true if record.assigned_to == user && record.phase.project.organization_id == user.organization_id

    phase_policy = Immo::Promo::PhasePolicy.new(user, record.phase)
    phase_policy.update?
  end

  def destroy?
    return false if record.completed?
    Immo::Promo::PhasePolicy.new(user, record.phase).update?
  end

  def assign_task?
    Immo::Promo::PhasePolicy.new(user, record.phase).update?
  end

  def log_time?
    return true if user_is_admin?
    same_organization? && (
      record.assigned_to == user ||
      user_has_permission?('immo_promo:time_tracking:manage')
    )
  end

  def complete_task?
    return true if user_is_admin?
    same_organization? && (
      record.assigned_to == user ||
      Immo::Promo::PhasePolicy.new(user, record.phase).update?
    )
  end

  def complete?
    return true if user_is_admin?
    return true if record.assigned_to == user
    return true if record.phase.project.project_manager_id == user.id

    phase_policy = Immo::Promo::PhasePolicy.new(user, record.phase)
    phase_policy.update?
  end

  def assign?
    return true if record.assigned_to == user && record.phase.project.organization_id == user.organization_id
    assign_task?
  end

  def my_tasks?
    # This is a class-level permission check
    # Allow any authenticated user to access their own tasks
    user.present?
  end

  def permitted_attributes
    [:name, :description, :task_type, :status, :priority, :start_date, 
     :end_date, :estimated_hours, :estimated_cost_cents, :workflow_status,
     checklist: []]
  end

  class Scope < Scope
    def resolve
      # Include tasks assigned to the user OR tasks from projects they have access to
      phase_scope = Pundit.policy_scope(user, Immo::Promo::Phase)
      scope.left_joins(:phase)
           .where('immo_promo_tasks.assigned_to_id = ? OR immo_promo_phases.id IN (?)',
                  user.id, phase_scope.select(:id))
           .distinct
    end
  end
end
