class Immo::Promo::Navbar::NavigationComponent < ApplicationComponent
  def initialize(current_project: nil)
    @current_project = current_project
  end

  private

  attr_reader :current_project

  def on_dashboard?
    controller_name == 'projects' && action_name == 'dashboard'
  end

  def on_projects_index?
    controller_name == 'projects' && action_name == 'index'
  end

  def projects_path
    helpers.immo_promo_engine.projects_path
  end

  def project_path
    helpers.immo_promo_engine.project_path(current_project)
  end
end