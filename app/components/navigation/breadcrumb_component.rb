class Navigation::BreadcrumbComponent < ApplicationComponent
  def initialize(items:, separator: :chevron, show_home: true, truncate: true, mobile_back: true, **options)
    @items = items
    @separator = separator # :chevron, :slash, :arrow, :dot, :ged
    @show_home = show_home
    @truncate = truncate
    @mobile_back = mobile_back
    @options = options
  end

  private

  attr_reader :items, :separator, :show_home, :truncate, :mobile_back, :options

  def wrapper_classes
    classes = ["flex mb-6"]
    classes << options[:class] if options[:class]
    classes.join(" ")
  end

  def separator_icon
    case separator
    when :chevron
      "chevron-right"
    when :slash
      nil # Use text
    when :arrow
      "arrow-right"
    when :dot
      nil # Use text
    when :ged
      nil # Use custom SVG
    else
      "chevron-right"
    end
  end

  def separator_text
    case separator
    when :slash
      "/"
    when :dot
      "•"
    else
      nil
    end
  end

  def custom_separator_svg
    return nil unless separator == :ged
    
    content_tag(:svg, class: "flex-shrink-0 h-5 w-5 text-gray-300", fill: "currentColor", viewBox: "0 0 20 20", "aria-hidden": "true") do
      content_tag(:path, nil, d: "M5.555 17.776l8-16 .894.448-8 16-.894-.448z")
    end
  end

  def truncated_items
    return items unless truncate && items.length > 3
    
    # Show first item, ellipsis, and last two items
    [items.first, { name: "...", path: nil, truncated: true }] + items.last(2)
  end


  def display_items
    @display_items ||= begin
      home_item = show_home ? [{ name: "Accueil", path: root_path, icon: "home" }] : []
      breadcrumb_items = truncate && items.length > 3 ? truncated_items : items
      home_item + breadcrumb_items
    end
  end

  def item_text(item)
    return item[:name] if item[:name].present?
    item[:title] || item[:label] || "Unknown"
  end

  def item_path(item)
    item[:path] || item[:url] || item[:href]
  end

  def root_path
    options[:root_path] || helpers.root_path
  end
end