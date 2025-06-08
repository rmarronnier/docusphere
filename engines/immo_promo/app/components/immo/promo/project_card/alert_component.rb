class Immo::Promo::ProjectCard::AlertComponent < ApplicationComponent
  def initialize(project:)
    @project = project
  end

  private

  attr_reader :project

  def is_delayed?
    project.respond_to?(:is_delayed?) && project.is_delayed?
  end
end