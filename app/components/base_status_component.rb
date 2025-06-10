# Base component for all status display components
class BaseStatusComponent < ApplicationComponent
  # Shared color mappings for consistency
  STATUS_COLORS = {
    # Success states
    success: 'green',
    completed: 'green',
    approved: 'green',
    active: 'green',
    published: 'green',
    
    # Warning states
    warning: 'yellow',
    pending: 'yellow',
    in_progress: 'yellow',
    processing: 'yellow',
    draft: 'yellow',
    
    # Error states
    error: 'red',
    failed: 'red',
    rejected: 'red',
    overdue: 'red',
    
    # Info states
    info: 'blue',
    new: 'blue',
    submitted: 'blue',
    
    # Neutral states
    neutral: 'gray',
    archived: 'gray',
    cancelled: 'gray',
    inactive: 'gray',
    locked: 'gray'
  }.freeze

  def initialize(status:, label: nil, size: :default, variant: :badge, **options)
    @status = status.to_s.downcase.to_sym
    @label = label || default_label
    @size = size
    @variant = variant
    @options = options
    @color = options.fetch(:color, status_color)
    @icon = options[:icon]
    @dot = options.fetch(:dot, false)
  end

  def call
    case @variant
    when :badge
      render_badge
    when :pill
      render_pill
    when :dot
      render_dot_status
    when :minimal
      render_minimal
    else
      render_badge
    end
  end

  protected

  def render_badge
    content_tag :span, class: badge_classes do
      safe_join([
        render_dot_indicator,
        render_icon,
        @label
      ].compact)
    end
  end

  def render_pill
    content_tag :span, class: pill_classes do
      safe_join([
        render_icon,
        @label
      ].compact)
    end
  end

  def render_dot_status
    content_tag :div, class: 'flex items-center gap-2' do
      safe_join([
        content_tag(:span, '', class: dot_classes),
        content_tag(:span, @label, class: 'text-sm text-gray-700')
      ])
    end
  end

  def render_minimal
    content_tag :span, @label, class: minimal_classes
  end

  def render_dot_indicator
    return unless @dot
    content_tag :span, '', class: "w-2 h-2 rounded-full bg-#{@color}-400"
  end

  def render_icon
    return unless @icon
    # This would integrate with IconComponent
    content_tag :span, @icon, class: 'inline-block w-4 h-4'
  end

  def badge_classes
    base = "inline-flex items-center gap-1 font-medium rounded-full"
    
    size_classes = case @size
    when :sm
      "px-2 py-0.5 text-xs"
    when :lg
      "px-3 py-1 text-sm"
    else
      "px-2.5 py-0.5 text-xs"
    end
    
    color_classes = "bg-#{@color}-100 text-#{@color}-800"
    
    [base, size_classes, color_classes, @options[:class]].compact.join(' ')
  end

  def pill_classes
    base = "inline-flex items-center gap-1.5 font-medium rounded-md"
    
    size_classes = case @size
    when :sm
      "px-2 py-1 text-xs"
    when :lg
      "px-4 py-2 text-base"
    else
      "px-3 py-1 text-sm"
    end
    
    color_classes = "bg-#{@color}-50 text-#{@color}-700 ring-1 ring-inset ring-#{@color}-600/20"
    
    [base, size_classes, color_classes, @options[:class]].compact.join(' ')
  end

  def dot_classes
    size = case @size
    when :sm
      "w-2 h-2"
    when :lg
      "w-3 h-3"
    else
      "w-2.5 h-2.5"
    end
    
    "#{size} rounded-full bg-#{@color}-400"
  end

  def minimal_classes
    base = "font-medium"
    
    size_classes = case @size
    when :sm
      "text-xs"
    when :lg
      "text-base"
    else
      "text-sm"
    end
    
    color_classes = "text-#{@color}-700"
    
    [base, size_classes, color_classes, @options[:class]].compact.join(' ')
  end

  def status_color
    STATUS_COLORS[@status] || 'gray'
  end

  def default_label
    @status.to_s.humanize
  end

  # Helper method for subclasses to add custom status mappings
  def self.add_status_colors(mappings)
    const_set(:CUSTOM_COLORS, mappings)
  end

  # Override in subclasses for custom color logic
  def custom_status_color
    return unless self.class.const_defined?(:CUSTOM_COLORS)
    self.class::CUSTOM_COLORS[@status]
  end
end