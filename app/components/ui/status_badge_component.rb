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
  
  def initialize(status: nil, label: nil, color: nil, size: :default, dot: false, removable: false, icon: nil, variant: :badge, **options)
    # Map legacy size names
    mapped_size = case size
                  when :small then :sm
                  when :medium then :default
                  when :large then :lg
                  else size
                  end
    
    @removable = removable
    @options = options
    
    # Pass the full set of options to super, don't pass color directly
    # since it will be computed automatically from status
    super(
      status: status || 'unknown',
      label: label,
      size: mapped_size,
      dot: dot,
      variant: variant,
      icon: icon,
      **options
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
    custom_classes = @options[:class]
    
    [base, size_classes, color_classes, custom_classes].compact.join(' ')
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
    custom_classes = @options[:class]
    
    [base, size_classes, color_classes, custom_classes].compact.join(' ')
  end
  
  def dot_indicator_classes
    "w-2 h-2 rounded-full bg-#{@color}-400"
  end
  
  def remove_button_classes
    "ml-1.5 inline-flex flex-shrink-0 h-4 w-4 rounded-full hover:bg-black hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white focus:ring-black focus:ring-opacity-20"
  end
  
  def remove_button_classes_pill
    "ml-2 inline-flex flex-shrink-0 h-5 w-5 rounded hover:bg-black hover:bg-opacity-10 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white focus:ring-black focus:ring-opacity-20"
  end
  
  protected
  
  def status_color
    custom_status_color || super
  end
end