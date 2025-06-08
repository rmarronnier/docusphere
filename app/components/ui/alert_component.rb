class Ui::AlertComponent < ApplicationComponent
  TYPES = {
    info: {
      container: 'bg-blue-50 border-blue-400',
      icon_color: 'text-blue-400',
      text_color: 'text-blue-700',
      icon: :information_circle
    },
    success: {
      container: 'bg-green-50 border-green-400',
      icon_color: 'text-green-400',
      text_color: 'text-green-700',
      icon: :check_circle
    },
    warning: {
      container: 'bg-yellow-50 border-yellow-400',
      icon_color: 'text-yellow-400',
      text_color: 'text-yellow-700',
      icon: :exclamation
    },
    error: {
      container: 'bg-red-50 border-red-400',
      icon_color: 'text-red-400',
      text_color: 'text-red-700',
      icon: :x_circle_filled
    }
  }.freeze
  
  def initialize(type: :info, title: nil, message: nil, dismissible: false, border_position: :left)
    @type = type.to_sym
    @title = title
    @message = message
    @dismissible = dismissible
    @border_position = border_position
  end
  
  private
  
  def type_config
    TYPES[@type] || TYPES[:info]
  end
  
  def container_classes
    base = "p-3 #{type_config[:container]}"
    border = case @border_position
             when :left then 'border-l-4'
             when :top then 'border-t-4'
             when :all then 'border'
             else 'border-l-4'
             end
    "#{base} #{border}"
  end
  
  def dismissible_data
    return {} unless @dismissible
    { controller: 'alert', action: 'click->alert#dismiss' }
  end
  
  def show_icon?
    true # Can be made configurable if needed
  end
  
end