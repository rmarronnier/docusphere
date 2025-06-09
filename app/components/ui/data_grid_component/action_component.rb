class Ui::DataGridComponent::ActionComponent < ApplicationComponent
  attr_reader :item, :actions, :style, :size, :gap, :show_labels, :dropdown_label

  def initialize(
    item:,
    actions: [],
    style: :inline, # :inline, :dropdown, :buttons
    size: :small,   # :small, :medium, :large
    gap: 2,
    show_labels: true,
    dropdown_label: "Actions"
  )
    @item = item
    @actions = actions
    @style = style
    @size = size
    @gap = gap
    @show_labels = show_labels
    @dropdown_label = dropdown_label
  end

  def call
    content_tag :div, class: "flex items-center gap-#{gap}" do
      if filtered_actions.any?
        case style
        when :dropdown
          render_dropdown
        when :buttons
          render_buttons
        else # :inline
          render_inline
        end
      end
    end
  end

  private

  def filtered_actions
    @filtered_actions ||= actions.select do |action|
      # Check condition
      next false if action[:condition] && !instance_exec(item, &action[:condition])
      
      # Check permission
      next false if action[:permission] && !helpers.can?(action[:permission], item)
      
      true
    end
  end

  def render_dropdown
    content_tag :div, class: "relative inline-block text-left", data: { controller: "dropdown" } do
      safe_join([
        button_tag(type: "button", 
                   class: "inline-flex items-center px-2 py-1 text-sm text-gray-700 hover:bg-gray-100 rounded-md",
                   data: { action: "click->dropdown#toggle" }) do
          safe_join([
            dropdown_label,
            icon_svg("chevron-down", class: "ml-1 h-4 w-4")
          ])
        end,
        content_tag(:div, 
                    class: "hidden absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5",
                    data: { dropdown_target: "menu" }) do
          content_tag :div, class: "py-1" do
            safe_join(filtered_actions.map { |action| render_dropdown_item(action) })
          end
        end
      ])
    end
  end

  def render_dropdown_item(action)
    link_to action[:path] || action[:url] || "#",
            class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100",
            **action_data_attributes(action) do
      safe_join([
        action[:icon] ? icon_svg(action[:icon], class: "inline-block mr-2 h-4 w-4") : nil,
        action[:label]
      ].compact)
    end
  end

  def render_buttons
    content_tag :div, class: "flex gap-#{gap}" do
      safe_join(filtered_actions.map { |action| render_button(action) })
    end
  end

  def render_button(action)
    link_to action[:path] || action[:url] || "#",
            class: action_classes(action),
            **action_data_attributes(action) do
      safe_join([
        action[:icon] ? icon_svg(action[:icon], class: icon_classes) : nil,
        show_labels ? action[:label] : nil
      ].compact)
    end
  end

  def render_inline
    safe_join(filtered_actions.map.with_index do |action, index|
      safe_join([
        link_to(action[:path] || action[:url] || "#",
                class: "text-blue-600 hover:text-blue-800 text-sm",
                **action_data_attributes(action)) do
          if action[:icon] && !show_labels
            icon_svg(action[:icon], class: "h-4 w-4")
          else
            action[:label]
          end
        end,
        index < filtered_actions.length - 1 ? content_tag(:span, " | ", class: "text-gray-300") : nil
      ].compact)
    end)
  end

  def action_classes(action)
    base = "inline-flex items-center justify-center rounded-md transition-colors"
    
    size_classes = case size
    when :small then "px-2 py-1 text-xs"
    when :medium then "px-3 py-1.5 text-sm"
    when :large then "px-4 py-2 text-base"
    else "px-2 py-1 text-xs"
    end

    style_classes = case action[:style]
    when :primary then "bg-blue-600 text-white hover:bg-blue-700"
    when :danger then "bg-red-600 text-white hover:bg-red-700"
    when :warning then "bg-yellow-600 text-white hover:bg-yellow-700"
    when :secondary then "bg-gray-600 text-white hover:bg-gray-700"
    when :ghost then "text-gray-700 hover:bg-gray-100"
    else "text-gray-700 hover:bg-gray-100"
    end

    "#{base} #{size_classes} #{style_classes}"
  end

  def icon_classes
    case size
    when :small then "h-3 w-3"
    when :large then "h-5 w-5"
    else "h-4 w-4"
    end + (show_labels ? " mr-1" : "")
  end

  def action_data_attributes(action)
    attrs = {}
    
    # Turbo confirmation
    if action[:confirm]
      attrs["data-turbo-confirm"] = action[:confirm]
    end

    # HTTP method
    if action[:method] && action[:method] != :get
      attrs["data-turbo-method"] = action[:method]
    end

    # Custom data attributes
    if action[:data]
      action[:data].each do |key, value|
        attrs["data-#{key.to_s.dasherize}"] = value
      end
    end

    attrs
  end

  def icon_svg(name, options = {})
    # Simple SVG icon implementation
    # In a real app, you'd use an IconComponent
    content_tag :svg, class: options[:class], fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
      case name
      when "eye"
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", 
            d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
      when "pencil"
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
      when "trash"
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
      when "chevron-down"
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M19 9l-7 7-7-7"
      else
        # Default icon
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M12 6v6m0 0v6m0-6h6m-6 0H6"
      end
    end
  end
end