class Ui::StatusBadgeComponent < ApplicationComponent
  def initialize(status:, mapping: nil, size: :sm)
    @status = status.to_s
    @mapping = mapping || default_mapping
    @size = size.to_sym
  end

  private

  attr_reader :status, :mapping, :size

  def badge_classes
    base_classes = "inline-flex items-center font-medium rounded-full"
    
    size_classes = case size
    when :xs
      "px-2 py-1 text-xs"
    when :lg
      "px-3 py-2 text-sm"
    else # :sm
      "px-2.5 py-0.5 text-xs"
    end

    color_classes = status_colors
    
    "#{base_classes} #{size_classes} #{color_classes}"
  end

  def status_colors
    mapping[status] || mapping['default'] || default_colors[status] || default_colors['default']
  end

  def default_mapping
    {
      # Document statuses
      'draft' => 'bg-gray-100 text-gray-800',
      'published' => 'bg-green-100 text-green-800',
      'locked' => 'bg-yellow-100 text-yellow-800',
      'archived' => 'bg-gray-100 text-gray-600',
      
      # Project statuses
      'planning' => 'bg-blue-100 text-blue-800',
      'development' => 'bg-purple-100 text-purple-800',
      'construction' => 'bg-orange-100 text-orange-800',
      'delivery' => 'bg-indigo-100 text-indigo-800',
      'completed' => 'bg-green-100 text-green-800',
      'cancelled' => 'bg-red-100 text-red-800',
      
      # Task/Phase statuses
      'pending' => 'bg-gray-100 text-gray-800',
      'in_progress' => 'bg-blue-100 text-blue-800',
      'delayed' => 'bg-red-100 text-red-800',
      
      # Processing statuses
      'processing' => 'bg-yellow-100 text-yellow-800',
      'failed' => 'bg-red-100 text-red-800',
      'success' => 'bg-green-100 text-green-800',
      
      # Workflow statuses
      'active' => 'bg-green-100 text-green-800',
      'paused' => 'bg-yellow-100 text-yellow-800',
      
      # Default
      'default' => 'bg-gray-100 text-gray-800'
    }
  end

  def default_colors
    default_mapping
  end

  def status_text
    I18n.t("statuses.#{status}", default: status.humanize)
  end
end