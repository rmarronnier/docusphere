class Dashboard::StatisticsWidget < ApplicationComponent
  attr_reader :widget_data, :user
  
  def initialize(widget_data:, user:)
    @widget_data = widget_data
    @user = user
  end
  
  private
  
  def statistics
    @statistics ||= widget_data[:data][:stats] || []
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
      'grid-cols-1 sm:grid-cols-2'
    when 3
      'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
    when 4
      'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4'
    else
      'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4'
    end
  end
  
  def stat_color_classes(color)
    case color
    when 'blue'
      'bg-blue-50 text-blue-600'
    when 'green'
      'bg-green-50 text-green-600'
    when 'purple'
      'bg-purple-50 text-purple-600'
    when 'orange'
      'bg-orange-50 text-orange-600'
    when 'red'
      'bg-red-50 text-red-600'
    when 'yellow'
      'bg-yellow-50 text-yellow-600'
    else
      'bg-gray-50 text-gray-600'
    end
  end
  
  def trend_icon_class(direction)
    case direction
    when 'up'
      'text-green-500'
    when 'down'
      'text-red-500'
    else
      'text-gray-400'
    end
  end
  
  def formatted_value(value)
    case value
    when Numeric
      if value.is_a?(Float)
        value.to_s
      else
        number_with_delimiter(value)
      end
    else
      value.to_s
    end
  end
  
  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
  
  def trend_text(trend)
    return '' unless trend && trend[:percentage]
    
    sign = trend[:direction] == 'down' ? '-' : '+'
    "#{sign}#{trend[:percentage]}%"
  end
end