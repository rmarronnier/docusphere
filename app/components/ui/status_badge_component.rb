class Ui::StatusBadgeComponent < BaseStatusComponent
  # Additional status mappings specific to this component
  add_status_colors(
    at_risk: 'orange',
    on_track: 'green',
    on_hold: 'yellow',
    not_started: 'gray',
    delayed: 'red',
    in_progress: 'blue'
  )
  
  def initialize(status: nil, label: nil, color: nil, size: :default, dot: false, removable: false)
    # Map legacy size names
    mapped_size = case size
                  when :small then :sm
                  when :medium then :default
                  when :large then :lg
                  else size
                  end
    
    @removable = removable
    
    # Pass the full set of options to super, don't pass color directly
    # since it will be computed automatically from status
    super(
      status: status || 'unknown',
      label: label,
      size: mapped_size,
      dot: dot
    )
    
    # Override color if explicitly provided
    @color = color if color.present?
  end
  
  private
  
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
    
    [base, size_classes, color_classes].compact.join(' ')
  end
  
  def dot_color_class
    "bg-#{@color}-400"
  end
  
  protected
  
  def status_color
    custom_status_color || super
  end
  
  def render_badge
    content_tag :span, class: badge_classes do
      safe_join([
        render_dot_indicator,
        render_icon,
        @label,
        render_remove_button
      ].compact)
    end
  end
  
  def render_remove_button
    return unless @removable
    
    content_tag :button, type: 'button',
                class: "ml-1.5 inline-flex flex-shrink-0 h-4 w-4 rounded-full hover:bg-black hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white focus:ring-black focus:ring-opacity-20",
                'data-action': "click->remove",
                'aria-label': "Remove #{@label}" do
      content_tag :svg, class: "h-2 w-2", fill: "none", stroke: "currentColor", 'stroke-width': "2", viewbox: "0 0 24 24", 'aria-hidden': "true", xmlns: "http://www.w3.org/2000/svg" do
        content_tag :path, '', 'stroke-linecap': "round", 'stroke-linejoin': "round", 'stroke-width': "2", d: "M6 18L18 6M6 6l12 12"
      end
    end
  end
end