class Immo::Promo::ProjectCard::HeaderComponent < ApplicationComponent
  def initialize(project:)
    @project = project
  end

  private

  attr_reader :project


  def project_path
    ImmoPromo::Engine.routes.url_helpers.project_path(project)
  end
end