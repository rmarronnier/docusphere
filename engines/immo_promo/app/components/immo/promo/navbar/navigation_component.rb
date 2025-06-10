class Immo::Promo::Navbar::NavigationComponent < ApplicationComponent
  def initialize(current_project: nil, on_dashboard: false, on_projects_index: false)
    @current_project = current_project
    @on_dashboard = on_dashboard
    @on_projects_index = on_projects_index
  end

  private

  attr_reader :current_project

  def on_dashboard?
    return @on_dashboard unless @on_dashboard.nil?
    controller_name == 'projects' && action_name == 'dashboard'
  rescue
    false
  end

  def on_projects_index?
    return @on_projects_index unless @on_projects_index.nil?
    controller_name == 'projects' && action_name == 'index'
  rescue
    false
  end

  def projects_path
    helpers.immo_promo_engine.projects_path
  end

  def project_path
    helpers.immo_promo_engine.project_path(current_project)
  end
end