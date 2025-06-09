class Navigation::BreadcrumbComponent < ApplicationComponent
  def initialize(items:, separator: :chevron, show_home: true, truncate: true, **options)
    @items = items
    @separator = separator # :chevron, :slash, :arrow, :dot
    @show_home = show_home
    @truncate = truncate
    @options = options
  end

  private

  attr_reader :items, :separator, :show_home, :truncate, :options

  def wrapper_classes
    classes = ["breadcrumb-wrapper flex items-center space-x-2 text-sm"]
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

  def truncated_items
    return items unless truncate && items.length > 3
    
    # Show first item, ellipsis, and last two items
    [items.first, { name: "...", path: nil, truncated: true }] + items.last(2)
  end

  def link_classes(item, index)
    classes = ["breadcrumb-link inline-flex items-center"]
    
    if index == display_items.length - 1
      # Last item (current page)
      classes << "text-gray-700 font-medium cursor-default"
    else
      # Clickable items
      classes << "text-gray-500 hover:text-gray-700 transition-colors duration-150"
    end
    
    classes.join(" ")
  end

  def display_items
    @display_items ||= begin
      all_items = []
      all_items << { name: "Home", path: root_path, icon: "home" } if show_home
      all_items + (truncate ? truncated_items : items)
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
    options[:root_path] || "/"
  end
end