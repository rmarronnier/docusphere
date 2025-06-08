class Immo::Promo::Navbar::MobileMenuComponent < ApplicationComponent
  private

  def on_dashboard?
    controller_name == 'projects' && action_name == 'dashboard'
  end

  def on_projects_index?
    controller_name == 'projects' && action_name == 'index'
  end

  def projects_path
    helpers.immo_promo_engine.projects_path
  end
end