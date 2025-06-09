class Ui::StatCardComponent < ApplicationComponent
  def initialize(title:, value:, subtitle: nil, icon: nil, trend: nil, trend_value: nil,
                 variant: :default, href: nil, loading: false, **options)
    @title = title
    @value = value
    @subtitle = subtitle
    @icon = icon
    @trend = trend # :up, :down, :neutral
    @trend_value = trend_value
    @variant = variant
    @href = href
    @loading = loading
    @options = options
  end

  private

  attr_reader :title, :value, :subtitle, :icon, :trend, :trend_value, :variant, :href, :loading, :options

  def wrapper_tag
    href.present? ? :a : :div
  end

  def wrapper_options
    opts = {
      class: wrapper_classes
    }
    opts[:href] = href if href.present?
    opts
  end

  def wrapper_classes
    classes = ["stat-card group relative overflow-hidden rounded-xl border bg-white p-6 transition-all duration-200"]
    
    case variant
    when :primary
      classes << "border-primary-200 bg-gradient-to-br from-primary-50 to-white"
    when :success
      classes << "border-success-200 bg-gradient-to-br from-success-50 to-white"
    when :warning
      classes << "border-warning-200 bg-gradient-to-br from-warning-50 to-white"
    when :danger
      classes << "border-danger-200 bg-gradient-to-br from-danger-50 to-white"
    else
      classes << "border-gray-200"
    end
    
    if href.present?
      classes << "hover:shadow-lg hover:-translate-y-0.5 cursor-pointer"
    else
      classes << "hover:shadow-md"
    end
    
    classes << options[:class] if options[:class]
    classes.join(" ")
  end

  def icon_classes
    "h-12 w-12 text-#{variant_color}-600"
  end

  def trend_icon
    case trend
    when :up
      "arrow-trending-up"
    when :down
      "arrow-trending-down"
    else
      "minus"
    end
  end

  def trend_color
    case trend
    when :up
      "text-success-600"
    when :down
      "text-danger-600"
    else
      "text-gray-500"
    end
  end

  def variant_color
    case variant
    when :primary then "primary"
    when :success then "success"
    when :warning then "warning"
    when :danger then "danger"
    else "gray"
    end
  end

  def skeleton_class(width = "w-full")
    "skeleton h-4 #{width}" if loading
  end

  def value_classes
    classes = ["text-3xl font-bold tracking-tight"]
    classes << "text-#{variant_color}-900" if variant != :default
    classes << "text-gray-900" if variant == :default
    classes.join(" ")
  end
end