class Immo::Promo::PhasePolicy < ApplicationPolicy
  def index?
    Immo::Promo::ProjectPolicy.new(user, record.project).show?
  end

  def show?
    Immo::Promo::ProjectPolicy.new(user, record.project).show?
  end

  def create?
    Immo::Promo::ProjectPolicy.new(user, record.project).update?
  end

  def update?
    return true if user_is_admin?
    project_policy = Immo::Promo::ProjectPolicy.new(user, record.project)
    project_policy.update? || (
      same_organization? &&
      record.responsible_user == user
    )
  end

  def destroy?
    return false unless record.tasks.empty? # Cannot delete phases with tasks
    return true if user_is_admin?
    # Only project manager can destroy phases
    record.project.project_manager == user
  end

  def manage_tasks?
    update?
  end

  def complete_phase?
    update? && record.can_start?
  end

  def complete?
    complete_phase?
  end

  class Scope < Scope
    def resolve
      # Phases are scoped through projects
      project_scope = Pundit.policy_scope(user, Immo::Promo::Project)
      scope.joins(:project).where(project: project_scope)
    end
  end
end
