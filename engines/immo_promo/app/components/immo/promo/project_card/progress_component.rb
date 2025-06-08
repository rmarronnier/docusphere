class Immo::Promo::ProjectCard::ProgressComponent < ApplicationComponent
  def initialize(project:)
    @project = project
  end

  private

  attr_reader :project
end