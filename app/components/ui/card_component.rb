class Ui::CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer
  renders_one :actions
  renders_one :subtitle
  renders_one :icon
  
  def initialize(title: nil, variant: :default, collapsible: false, loading: false, 
                 href: nil, clickable: false, classes: nil, padded: true,
                 hover: true, shadow: :md, rounded: :xl, border: true, **options)
    @title = title
    @variant = variant
    @collapsible = collapsible
    @loading = loading
    @href = href
    @clickable = clickable || href.present?
    @custom_classes = classes
    @padded = padded
    @hover = hover
    @shadow = shadow
    @rounded = rounded
    @border = border
    @options = options
  end

  private

  attr_reader :title, :variant, :collapsible, :loading, :href, :clickable, 
              :custom_classes, :padded, :hover, :shadow, :rounded, :border, :options

  def classes
    css_classes = ["card", "bg-white", "overflow-hidden"]
    
    # Variant styles
    case variant
    when :flat
      css_classes << "card-flat"
    when :bordered
      css_classes << "card-bordered"
    when :gradient
      css_classes << "bg-gradient-to-br from-white to-gray-50"
    when :primary
      css_classes << "bg-gradient-to-br from-primary-50 to-white border-primary-200"
    when :success
      css_classes << "bg-gradient-to-br from-success-50 to-white border-success-200"
    else
      css_classes << "card"
    end
    
    # Interactive states
    if clickable
      css_classes << "relative cursor-pointer transform transition-all duration-200"
      css_classes << "hover:shadow-lg hover:-translate-y-0.5 active:translate-y-0" if hover
    elsif hover && !loading
      css_classes << "transition-shadow duration-200 hover:shadow-lg"
    end
    
    # Shadow
    css_classes << shadow_class if shadow
    
    # Rounded corners
    css_classes << rounded_class if rounded
    
    # Border
    css_classes << "border border-gray-100" if border && variant == :default
    
    # Loading state
    css_classes << "animate-pulse" if loading
    
    # Custom classes
    css_classes << custom_classes if custom_classes
    
    css_classes.compact.join(" ")
  end
  
  def shadow_class
    case shadow
    when :none then nil
    when :sm then "shadow-sm"
    when :md then "shadow-md"
    when :lg then "shadow-lg"
    when :xl then "shadow-xl"
    when :"2xl" then "shadow-2xl"
    else "shadow-md"
    end
  end
  
  def rounded_class
    case rounded
    when :none then "rounded-none"
    when :sm then "rounded-sm"
    when :md then "rounded-md"
    when :lg then "rounded-lg"
    when :xl then "rounded-xl"
    when :"2xl" then "rounded-2xl"
    when :full then "rounded-full"
    else "rounded-xl"
    end
  end

  def with_header?
    title.present? || subtitle? || actions? || header?
  end

  def card_attributes
    attrs = { class: classes }
    attrs["data-controller"] = "collapse" if collapsible
    
    if href.present?
      attrs[:href] = href
      attrs[:class] += " block"
    end
    
    attrs.merge(options.except(:class))
  end
  
  def wrapper_tag
    href.present? ? :a : :div
  end

  def content_attributes
    css_classes = ["card-body"]
    css_classes << "p-0" unless padded
    
    attrs = { class: css_classes.join(" ") }
    attrs["data-collapse-target"] = "content" if collapsible
    attrs
  end
  
  def header_classes
    "card-header flex items-center justify-between"
  end
  
  def loading_placeholder
    content_tag(:div, class: "p-6 space-y-4") do
      safe_join([
        content_tag(:div, nil, class: "h-4 bg-gray-200 rounded w-3/4 animate-pulse"),
        content_tag(:div, nil, class: "h-4 bg-gray-200 rounded w-1/2 animate-pulse"),
        content_tag(:div, nil, class: "h-4 bg-gray-200 rounded w-5/6 animate-pulse")
      ])
    end
  end
end