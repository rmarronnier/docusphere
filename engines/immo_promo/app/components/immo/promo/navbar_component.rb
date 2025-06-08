class Immo::Promo::NavbarComponent < ApplicationComponent
  def initialize(current_user:, current_project: nil)
    @current_user = current_user
    @current_project = current_project
  end

  private

  attr_reader :current_user, :current_project

  def on_project_view?
    current_project.present?
  end
end