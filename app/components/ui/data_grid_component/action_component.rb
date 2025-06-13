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

  def icon_size
    case size
    when :small then 3
    when :large then 5
    else 4
    end
  end
end