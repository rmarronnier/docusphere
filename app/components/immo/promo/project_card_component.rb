class Immo::Promo::ProjectCardComponent < ApplicationComponent
  def initialize(project:, show_actions: true)
    @project = project
    @show_actions = show_actions
  end

  private

  attr_reader :project, :show_actions

  def status_class
    case project.status
    when 'planning' then 'bg-blue-100 text-blue-800'
    when 'development' then 'bg-purple-100 text-purple-800'  
    when 'construction' then 'bg-yellow-100 text-yellow-800'
    when 'delivery' then 'bg-orange-100 text-orange-800'
    when 'completed' then 'bg-green-100 text-green-800'
    else 'bg-gray-100 text-gray-800'
    end
  end

  def progress_color
    case project.completion_percentage
    when 0..25 then 'bg-red-600'
    when 26..50 then 'bg-yellow-600'
    when 51..75 then 'bg-blue-600'
    else 'bg-green-600'
    end
  end

  def is_delayed?
    project.respond_to?(:is_delayed?) && project.is_delayed?
  end

  def formatted_surface_area
    return nil unless project.total_surface_area
    number_with_delimiter(project.total_surface_area.to_i)
  end

  def formatted_start_date
    project.start_date&.strftime('%d/%m/%Y') || 'À définir'
  end

  def formatted_end_date
    project.end_date&.strftime('%d/%m/%Y') || 'À définir'
  end
end