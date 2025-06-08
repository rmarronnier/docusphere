class Immo::Promo::Navbar::LogoComponent < ApplicationComponent
  private

  def projects_path
    helpers.immo_promo_engine.projects_path
  end
end