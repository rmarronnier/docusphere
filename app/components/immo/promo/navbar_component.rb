class Immo::Promo::NavbarComponent < ApplicationComponent
  def initialize(current_user:, current_project: nil)
    @current_user = current_user
    @current_project = current_project
  end

  private

  attr_reader :current_user, :current_project

  def on_dashboard?
    controller_name == 'projects' && action_name == 'dashboard'
  end

  def on_project_view?
    current_project.present?
  end

  def can_create_project?
    policy(Immo::Promo::Project).create?
  end

  def can_edit_project?
    return false unless current_project
    policy(current_project).update?
  end

  def can_manage_stakeholders?
    return false unless current_project
    policy(current_project).manage_stakeholders?
  end

  def can_manage_budget?
    return false unless current_project
    policy(current_project).manage_budget?
  end

  def can_manage_permits?
    return false unless current_project
    policy(current_project).manage_permits?
  end

  def policy(record)
    Pundit.policy(current_user, record)
  end
end