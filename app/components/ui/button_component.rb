class Ui::ButtonComponent < ApplicationComponent
  renders_many :dropdown_items, lambda { |text:, href:, method: :get, **options|
    link_to text, href, method: method, class: "dropdown-item", **options
  }
  
  def initialize(text: nil, variant: :primary, size: :md, icon: nil, icon_position: :left, 
                 loading: false, disabled: false, href: nil, group_item: false, group: false,
                 tooltip: nil, aria_label: nil, dropdown: false, **options)
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
    @options = options
    
    # Validate icon-only buttons have aria-label
    if icon && !text && !aria_label
      raise ArgumentError, "aria_label is required for icon-only buttons"
    end
  end

  private

  attr_reader :text, :variant, :size, :icon, :icon_position, :loading, :disabled, 
              :href, :group_item, :tooltip, :aria_label, :dropdown, :options

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
    
    # Custom classes
    base_classes << options[:class] if options[:class]
    
    base_classes.compact.join(" ")
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
    opts["data-tooltip-position"] = "top" if tooltip
    
    if dropdown
      opts["data-controller"] = "dropdown"
      opts["data-action"] = "click->dropdown#toggle"
    end
    
    opts
  end

  def render_icon
    return unless icon
    
    # Simple icon representation for testing
    content_tag(:i, "", class: "icon-#{icon} btn-icon")
  end
  
  def render_spinner
    content_tag(:span, "", class: "spinner")
  end

  def content_text
    text || content
  end
end