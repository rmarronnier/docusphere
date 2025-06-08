class Immo::Promo::ProjectCard::DatesComponent < ApplicationComponent
  def initialize(project:)
    @project = project
  end

  private

  attr_reader :project

  def formatted_start_date
    project.start_date&.strftime('%d/%m/%Y') || 'À définir'
  end

  def formatted_end_date
    project.end_date&.strftime('%d/%m/%Y') || 'À définir'
  end
end