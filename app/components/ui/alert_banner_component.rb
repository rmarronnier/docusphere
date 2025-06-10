class Ui::AlertBannerComponent < ApplicationComponent
  include Themeable
  include Localizable
  
  def initialize(alerts:, type: 'warning', title: nil, icon: nil, dismissible: false, **options)
    @alerts = Array(alerts).compact
    @type = type.to_s
    @title = title || default_title
    @icon = icon || default_icon
    @dismissible = dismissible
    @options = options
  end

  private

  attr_reader :alerts, :type, :title, :icon, :dismissible, :options

  def default_title
    component_t("title.#{type}", default: type.humanize)
  end

  def default_icon
    case type
    when 'danger', 'critical', 'error'
      'exclamation-circle'
    when 'warning'
      'exclamation-triangle'
    when 'info'
      'information-circle'
    when 'success'
      'check-circle'
    else
      'information-circle'
    end
  end

  def type_classes
    @type_classes ||= case type
    when 'danger', 'critical', 'error'
      {
        bg: 'bg-red-50',
        border: 'border-red-200',
        title_color: 'text-red-800',
        icon_color: 'text-red-600',
        item_bg: 'bg-white',
        text_color: 'text-red-900',
        subtitle_color: 'text-red-700',
        dismiss_hover: 'hover:bg-red-100'
      }
    when 'warning'
      {
        bg: 'bg-yellow-50',
        border: 'border-yellow-200',
        title_color: 'text-yellow-800',
        icon_color: 'text-yellow-600',
        item_bg: 'bg-white',
        text_color: 'text-yellow-900',
        subtitle_color: 'text-yellow-700',
        dismiss_hover: 'hover:bg-yellow-100'
      }
    when 'info'
      {
        bg: 'bg-blue-50',
        border: 'border-blue-200',
        title_color: 'text-blue-800',
        icon_color: 'text-blue-600',
        item_bg: 'bg-white',
        text_color: 'text-blue-900',
        subtitle_color: 'text-blue-700',
        dismiss_hover: 'hover:bg-blue-100'
      }
    when 'success'
      {
        bg: 'bg-green-50',
        border: 'border-green-200',
        title_color: 'text-green-800',
        icon_color: 'text-green-600',
        item_bg: 'bg-white',
        text_color: 'text-green-900',
        subtitle_color: 'text-green-700',
        dismiss_hover: 'hover:bg-green-100'
      }
    else
      {
        bg: 'bg-gray-50',
        border: 'border-gray-200',
        title_color: 'text-gray-800',
        icon_color: 'text-gray-600',
        item_bg: 'bg-white',
        text_color: 'text-gray-900',
        subtitle_color: 'text-gray-700',
        dismiss_hover: 'hover:bg-gray-100'
      }
    end
  end

  def styles
    type_classes
  end

  def container_classes
    classes = [styles[:bg], 'border', styles[:border], 'rounded-lg p-6']
    classes << 'relative' if dismissible
    classes << options[:class] if options[:class]
    classes.join(' ')
  end

  def severity_badge_classes(severity)
    case severity.to_s
    when 'critical', 'high'
      'bg-red-100 text-red-800'
    when 'medium'
      'bg-yellow-100 text-yellow-800'
    when 'low'
      'bg-green-100 text-green-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  # Normalize alert structure
  def normalize_alert(alert)
    return { message: alert.to_s } if alert.is_a?(String)
    
    alert = alert.with_indifferent_access if alert.respond_to?(:with_indifferent_access)
    
    {
      title: alert[:title],
      message: alert[:message] || alert[:description],
      severity: alert[:severity],
      action: alert[:action]
    }
  end
end