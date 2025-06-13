class Ui::FlashAlertComponent < ApplicationComponent
  # Map Rails flash types to component types
  FLASH_TYPE_MAPPING = {
    'notice' => :success,
    'alert' => :error,
    'error' => :error,
    'success' => :success,
    'warning' => :warning,
    'info' => :info
  }.freeze

  # Configuration for each type
  TYPE_CONFIG = {
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
      icon: :x_circle
    }
  }.freeze

  def initialize(type:, message:, dismissible: true, show_icon: true, html_safe: false)
    @flash_type = type.to_s
    @type = map_flash_type(@flash_type)
    @message = message
    @dismissible = dismissible
    @show_icon = show_icon
    @html_safe = html_safe
  end

  private

  def map_flash_type(flash_type)
    FLASH_TYPE_MAPPING[flash_type] || :info
  end

  def type_config
    TYPE_CONFIG[@type] || TYPE_CONFIG[:info]
  end

  def container_classes
    base_classes = "relative flex p-4 rounded-md mb-4 #{type_config[:container]} border"
    dismissible_classes = @dismissible ? "pr-12" : ""
    "#{base_classes} #{dismissible_classes}"
  end

  def icon_classes
    "h-5 w-5 #{type_config[:icon_color]}"
  end

  def text_classes
    "text-sm #{type_config[:text_color]}"
  end

  def aria_live_value
    case @type
    when :error, :warning
      'assertive'
    else
      'polite'
    end
  end

  def aria_atomic_value
    'true'
  end

  def dismissible_data
    return {} unless @dismissible
    { 
      'data-controller': 'alert',
      'data-turbo-temporary': 'true'
    }
  end

  def render_message
    if @html_safe && @message.html_safe?
      @message
    else
      @message
    end
  end
end