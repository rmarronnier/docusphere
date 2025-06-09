class Ui::ButtonComponent < ApplicationComponent
  renders_many :dropdown_items, lambda { |text:, href:, method: :get, icon: nil, divider: false, **options|
    if divider
      content_tag(:div, nil, class: "dropdown-divider")
    else
      link_to href, method: method, class: "dropdown-item", **options do
        safe_join([
          icon ? render(Ui::IconComponent.new(name: icon, size: 4, css_class: "mr-2")) : nil,
          content_tag(:span, text)
        ].compact)
      end
    end
  }
  
  def initialize(text: nil, variant: :primary, size: :md, icon: nil, icon_position: :left, 
                 loading: false, disabled: false, href: nil, group_item: false, group: false,
                 tooltip: nil, aria_label: nil, dropdown: false, full_width: false,
                 rounded: :lg, shadow: true, animate: true, **options)
    @text = text
    @variant = variant
    @size = size
    @icon = icon
    @icon_position = icon_position
    @loading = loading
    @disabled = disabled || loading
    @href = href
    @group_item = group_item || group
    @tooltip = tooltip
    @aria_label = aria_label
    @dropdown = dropdown
    @full_width = full_width
    @rounded = rounded
    @shadow = shadow
    @animate = animate
    @options = options
    
    # Validate icon-only buttons have aria-label
    if icon && !text && !aria_label
      raise ArgumentError, "aria_label is required for icon-only buttons"
    end
  end

  private

  attr_reader :text, :variant, :size, :icon, :icon_position, :loading, :disabled, 
              :href, :group_item, :tooltip, :aria_label, :dropdown, :full_width,
              :rounded, :shadow, :animate, :options

  def classes
    base_classes = ["btn"]
    
    # Variant classes
    base_classes << "btn-#{variant}"
    
    # Size classes
    base_classes << "btn-#{size}"
    
    # State classes
    base_classes << "btn-loading" if loading
    base_classes << "btn-disabled" if disabled
    base_classes << "btn-icon-only" if icon && !text
    base_classes << "btn-group-item" if group_item
    base_classes << "w-full" if full_width
    
    # Rounded classes
    base_classes << rounded_class unless group_item
    
    # Animation classes
    base_classes << "transform active:scale-95 transition-all duration-150" if animate && !disabled
    
    # Shadow classes
    base_classes << shadow_class if shadow && !group_item
    
    # Custom classes
    base_classes << options[:class] if options[:class]
    
    base_classes.compact.join(" ")
  end
  
  def rounded_class
    case rounded
    when :none then "rounded-none"
    when :sm then "rounded-sm"
    when :md then "rounded-md"
    when :lg then "rounded-lg"
    when :xl then "rounded-xl"
    when :full then "rounded-full"
    else "rounded-lg"
    end
  end
  
  def shadow_class
    case variant
    when :primary, :success, :warning, :danger
      "shadow-sm hover:shadow-md"
    when :secondary
      "shadow-sm hover:shadow"
    when :ghost
      nil
    else
      "shadow-sm"
    end
  end

  def html_options
    opts = options.except(:class).merge(
      class: classes,
      disabled: disabled
    )
    
    opts["aria-label"] = aria_label if aria_label
    opts["aria-busy"] = "true" if loading
    opts["aria-disabled"] = "true" if disabled
    opts["data-tooltip"] = tooltip if tooltip
    opts["data-tooltip-position"] = options[:tooltip_position] || "top" if tooltip
    
    if dropdown
      opts["data-controller"] = [opts["data-controller"], "dropdown"].compact.join(" ")
      opts["data-action"] = [opts["data-action"], "click->dropdown#toggle"].compact.join(" ")
      opts["aria-haspopup"] = "true"
      opts["aria-expanded"] = "false"
    end
    
    # Add ripple effect for touch devices
    if animate && !disabled
      opts["data-controller"] = [opts["data-controller"], "ripple"].compact.join(" ")
    end
    
    opts
  end

  def render_icon
    return unless icon
    
    render(Ui::IconComponent.new(
      name: icon,
      size: icon_size,
      css_class: "btn-icon #{icon_classes}"
    ))
  end
  
  def icon_size
    case size
    when :xs, :sm then 4
    when :md then 5
    when :lg then 6
    when :xl then 7
    else 5
    end
  end
  
  def icon_classes
    classes = []
    classes << "mr-2" if icon_position == :left && text.present?
    classes << "ml-2" if icon_position == :right && text.present?
    classes.join(" ")
  end
  
  def render_spinner
    content_tag(:svg, class: "animate-spin h-#{icon_size} w-#{icon_size} text-current", xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24") do
      content_tag(:circle, nil, class: "opacity-25", cx: "12", cy: "12", r: "10", stroke: "currentColor", "stroke-width": "4") +
      content_tag(:path, nil, class: "opacity-75", fill: "currentColor", d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")
    end
  end

  def content_text
    return content if text.nil? && content.present?
    
    content_tag(:span, text, class: text_classes)
  end
  
  def text_classes
    classes = []
    classes << "truncate" if options[:truncate]
    classes.join(" ").presence
  end
  
  # Support for button groups
  def self.group(**options, &block)
    content_tag(:div, class: "btn-group #{options[:class]}".strip, role: "group") do
      capture(&block)
    end
  end
end