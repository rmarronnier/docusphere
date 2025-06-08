class Immo::Promo::ProjectCard::HeaderComponent < ApplicationComponent
  def initialize(project:)
    @project = project
  end

  private

  attr_reader :project

  def status_color_mapping
    case project.status
    when 'planning' then :blue
    when 'pre_construction' then :purple  
    when 'construction' then :yellow
    when 'finishing' then :indigo
    when 'delivered' then :orange
    when 'completed' then :green
    when 'cancelled' then :red
    else :gray
    end
  end

  def project_path
    ImmoPromo::Engine.routes.url_helpers.project_path(project)
  end
end