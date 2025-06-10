class Dashboard::QuickAccessWidget < ApplicationComponent
  attr_reader :widget_data, :user
  
  def initialize(widget_data:, user:)
    @widget_data = widget_data
    @user = user
  end
  
  private
  
  def quick_links
    @quick_links ||= widget_data[:data][:links] || []
  end
  
  def link_limit
    widget_data.dig(:config, :limit) || 8
  end
  
  def columns
    widget_data.dig(:config, :columns) || 4
  end
  
  def loading?
    widget_data[:loading] == true
  end
  
  def grid_class
    case columns
    when 1
      'grid-cols-1'
    when 2
      'grid-cols-2'
    when 3
      'grid-cols-3'
    when 4
      'grid-cols-2 md:grid-cols-4'
    else
      'grid-cols-2 md:grid-cols-4'
    end
  end
  
  def link_color_classes(color)
    case color
    when 'blue'
      'bg-blue-50 text-blue-600 hover:bg-blue-100'
    when 'green'
      'bg-green-50 text-green-600 hover:bg-green-100'
    when 'purple'
      'bg-purple-50 text-purple-600 hover:bg-purple-100'
    when 'orange'
      'bg-orange-50 text-orange-600 hover:bg-orange-100'
    when 'red'
      'bg-red-50 text-red-600 hover:bg-red-100'
    when 'yellow'
      'bg-yellow-50 text-yellow-600 hover:bg-yellow-100'
    else
      'bg-gray-50 text-gray-600 hover:bg-gray-100'
    end
  end
  
  def icon_class(icon_name)
    # This would normally map to specific SVG icons
    # For now, we'll use generic icons
    'h-6 w-6'
  end
end