# frozen_string_literal: true

class Ui::ActionDropdownComponent < ApplicationComponent
  def initialize(
    actions:,
    trigger_style: :icon_button,
    trigger_text: nil,
    trigger_icon: nil,
    trigger_variant: :secondary,
    trigger_size: :sm,
    position: "right",
    menu_width: "w-56",
    z_index: "z-50",
    data: {}
  )
    @actions = actions
    @trigger_style = trigger_style
    @trigger_text = trigger_text
    @trigger_icon = trigger_icon || default_trigger_icon
    @trigger_variant = trigger_variant
    @trigger_size = trigger_size
    @position = position
    @menu_width = menu_width
    @z_index = z_index
    @data = data
    
    validate_actions!
  end

  private

  attr_reader :actions, :trigger_style, :trigger_text, :trigger_icon, :trigger_variant,
              :trigger_size, :position, :menu_width, :z_index, :data

  def validate_actions!
    raise ArgumentError, "actions must be an Array" unless actions.is_a?(Array)
    
    actions.each_with_index do |action, index|
      next if action[:divider] == true
      
      unless action[:label].present?
        raise ArgumentError, "action at index #{index} must have a :label"
      end
      
      unless action[:href].present? || action[:action].present? || action[:data].present?
        raise ArgumentError, "action at index #{index} must have either :href, :action, or :data"
      end
    end
  end

  def trigger_button_classes
    base_classes = %w[
      relative inline-flex items-center font-medium focus:outline-none 
      focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500
    ]
    
    case trigger_style
    when :icon_button
      base_classes += icon_button_classes
    when :button
      base_classes += button_classes
    when :link
      base_classes += link_classes
    when :ghost
      base_classes += ghost_button_classes
    else
      base_classes += button_classes
    end
    
    base_classes.join(" ")
  end
  
  def icon_button_classes
    size_classes = case trigger_size
                  when :xs then %w[p-1]
                  when :sm then %w[p-1.5]
                  when :md then %w[p-2]
                  when :lg then %w[p-2.5]
                  else %w[p-1.5]
                  end
    
    variant_classes = case trigger_variant
                     when :primary then %w[bg-indigo-600 text-white hover:bg-indigo-700]
                     when :secondary then %w[bg-white text-gray-400 hover:text-gray-500 border border-gray-300 hover:bg-gray-50]
                     when :ghost then %w[text-gray-400 hover:text-gray-500 hover:bg-gray-100]
                     else %w[bg-white text-gray-400 hover:text-gray-500 border border-gray-300 hover:bg-gray-50]
                     end
    
    size_classes + variant_classes + %w[rounded-md shadow-sm]
  end
  
  def button_classes
    size_classes = case trigger_size
                  when :xs then %w[px-2 py-1 text-xs]
                  when :sm then %w[px-3 py-2 text-sm]
                  when :md then %w[px-4 py-2 text-sm]
                  when :lg then %w[px-4 py-2 text-base]
                  else %w[px-3 py-2 text-sm]
                  end
    
    variant_classes = case trigger_variant
                     when :primary then %w[bg-indigo-600 text-white hover:bg-indigo-700 border-indigo-600]
                     when :secondary then %w[bg-white text-gray-700 hover:bg-gray-50 border-gray-300]
                     when :ghost then %w[bg-transparent text-gray-700 hover:bg-gray-100 border-transparent]
                     else %w[bg-white text-gray-700 hover:bg-gray-50 border-gray-300]
                     end
    
    size_classes + variant_classes + %w[border rounded-md shadow-sm]
  end
  
  def link_classes
    %w[text-gray-500 hover:text-gray-700 underline]
  end
  
  def ghost_button_classes
    size_classes = case trigger_size
                  when :xs then %w[p-1]
                  when :sm then %w[p-1.5]
                  when :md then %w[p-2]
                  when :lg then %w[p-2.5]
                  else %w[p-1.5]
                  end
    
    size_classes + %w[text-gray-400 hover:text-gray-500 hover:bg-gray-100 rounded-md]
  end

  def menu_position_classes
    case position
    when "left"
      "left-0"
    when "center"
      "left-1/2 transform -translate-x-1/2"
    else
      "right-0"
    end
  end

  def trigger_icon_size
    case trigger_size
    when :xs then 3
    when :sm then 4
    when :md then 5
    when :lg then 6
    else 4
    end
  end

  def default_trigger_icon
    :menu
  end
  
  def dropdown_controller_data
    base_data = { controller: "dropdown" }
    base_data.merge!(data) if data.present?
    base_data
  end

  def action_classes(action)
    base_classes = %w[
      group flex items-center px-4 py-2 text-sm w-full text-left
      focus:outline-none focus:bg-gray-100
    ]
    
    if action[:danger]
      base_classes += %w[text-red-700 hover:bg-red-50 hover:text-red-800]
    else
      base_classes += %w[text-gray-700 hover:bg-gray-100 hover:text-gray-900]
    end
    
    base_classes.join(" ")
  end
  
  def action_icon_classes(action)
    base_classes = %w[mr-3]
    
    if action[:danger]
      base_classes += %w[text-red-500 group-hover:text-red-600]
    else
      base_classes += %w[text-gray-400 group-hover:text-gray-500]
    end
    
    base_classes.join(" ")
  end
  
  def action_data_attributes(action)
    action_data = {}
    
    # Handle Rails UJS attributes
    if action[:method] && action[:method] != :get
      action_data[:turbo_method] = action[:method]
    end
    
    if action[:confirm]
      action_data[:turbo_confirm] = action[:confirm]
    end
    
    # Handle custom data attributes
    if action[:data]
      action_data.merge!(action[:data])
    end
    
    action_data
  end
  
  def render_action_link(action, action_data)
    if action[:href]
      link_to action[:href], 
              class: action_classes(action),
              role: "menuitem",
              tabindex: "-1",
              data: action_data do
        action_content(action)
      end
    elsif action[:action]
      link_to action[:action],
              class: action_classes(action),
              role: "menuitem", 
              tabindex: "-1",
              data: action_data do
        action_content(action)
      end
    else
      # Button for JavaScript actions only
      button_tag type: :button,
                 class: action_classes(action),
                 role: "menuitem",
                 tabindex: "-1",
                 data: action_data do
        action_content(action)
      end
    end
  end
  
  def action_content(action)
    safe_join([
      action_icon(action),
      content_tag(:span, action[:label])
    ].compact)
  end
  
  def action_icon(action)
    return unless action[:icon]
    
    render Ui::IconComponent.new(
      name: action[:icon].to_sym,
      size: 4,
      css_class: action_icon_classes(action)
    )
  end
  
  def trigger_aria_label
    return trigger_text if trigger_text.present?
    return "Actions" if trigger_style == :icon_button
    "Options"
  end
end