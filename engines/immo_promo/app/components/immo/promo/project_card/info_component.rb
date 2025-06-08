class Immo::Promo::ProjectCard::InfoComponent < ApplicationComponent
  def initialize(project:)
    @project = project
  end

  private

  attr_reader :project

  def formatted_surface_area
    return nil unless project.total_surface_area
    number_with_delimiter(project.total_surface_area.to_i)
  end
end