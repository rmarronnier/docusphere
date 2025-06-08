class Immo::Promo::Navbar::ProjectActionsComponent < ApplicationComponent
  def initialize(current_user:, current_project:)
    @current_user = current_user
    @current_project = current_project
  end

  private

  attr_reader :current_user, :current_project

  def can_edit_project?
    policy(current_project).update?
  end

  def can_manage_stakeholders?
    policy(current_project).manage_stakeholders?
  end

  def can_manage_budget?
    policy(current_project).manage_budget?
  end

  def can_manage_permits?
    policy(current_project).manage_permits?
  end

  def policy(record)
    Pundit.policy(current_user, record)
  end

  def edit_project_path
    helpers.immo_promo_engine.edit_project_path(current_project)
  end

  def project_stakeholders_path
    helpers.immo_promo_engine.project_stakeholders_path(current_project)
  end

  def project_permits_path
    helpers.immo_promo_engine.project_permits_path(current_project)
  end

  def project_budgets_path
    helpers.immo_promo_engine.project_budgets_path(current_project)
  end
end