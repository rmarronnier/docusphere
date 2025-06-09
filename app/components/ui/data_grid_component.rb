class Ui::DataGridComponent < ApplicationComponent
  renders_many :columns, Ui::DataGridComponent::ColumnComponent
  
  renders_one :empty_state
  
  # Configuration for empty state
  attr_reader :empty_state_config
  
  def configure_empty_state(message: nil, icon: "document", show_icon: true)
    @empty_state_config = {
      message: message,
      icon: icon,
      show_icon: show_icon
    }
  end
  
  # Configuration for row actions
  attr_reader :row_actions_config
  
  def configure_actions(style: :inline, size: :small, show_labels: true, gap: 2, dropdown_label: "Actions")
    @row_actions_config = {
      style: style,
      size: size,
      show_labels: show_labels,
      gap: gap,
      dropdown_label: dropdown_label,
      actions: []
    }
  end
  
  # Current sort state
  attr_reader :current_sort_key, :current_sort_direction
  
  def set_sort(key:, direction: "asc")
    @current_sort_key = key
    @current_sort_direction = direction
  end
  
  def with_action(label:, path: nil, **options, &block)
    @row_actions_config ||= { style: :inline, size: :small, show_labels: true, gap: 2, dropdown_label: "Actions", actions: [] }
    action = { label: label, **options }
    action[:path] = path if path
    action[:block] = block if block_given?
    @row_actions_config[:actions] << action
  end
  
  def actions?
    @row_actions_config && @row_actions_config[:actions].any?
  end

  def initialize(data:, striped: true, hover: true, loading: false, 
                 selectable: false, selected: [], bordered: true,
                 responsive: true, compact: false, **options)
    @data = data
    @striped = striped
    @hover = hover
    @loading = loading
    @selectable = selectable
    @selected = selected
    @bordered = bordered
    @responsive = responsive
    @compact = compact
    @options = options
  end

  private

  attr_reader :data, :striped, :hover, :loading, :selectable, :selected,
              :bordered, :responsive, :compact, :options

  def wrapper_classes
    classes = ["data-grid-wrapper"]
    classes << "overflow-x-auto" if responsive
    classes << "shadow-sm ring-1 ring-black ring-opacity-5 rounded-lg" if bordered
    classes << options[:class] if options[:class]
    classes.join(" ")
  end

  def table_classes
    classes = ["min-w-full divide-y divide-gray-200"]
    classes << "table-striped" if striped
    classes << "table-hover" if hover
    classes.join(" ")
  end


  def row_classes(index)
    classes = []
    classes << "bg-gray-50" if striped && index.odd?
    classes << "hover:bg-gray-50" if hover
    classes << "cursor-pointer" if options[:row_click]
    classes.join(" ")
  end


  def loading_rows
    5.times.map do
      content_tag(:tr) do
        column_count = columns? ? columns.compact.size : 0
        column_count.times.map do
          content_tag(:td, class: "px-6 py-4 whitespace-nowrap text-sm") do
            content_tag(:div, nil, class: "h-4 bg-gray-200 rounded animate-pulse")
          end
        end.join.html_safe
      end
    end.join.html_safe
  end

  private

  def build_actions_for_item(item)
    return [] unless row_actions_config
    
    row_actions_config[:actions].map do |action|
      if action[:block]
        # If action has a block, evaluate it with the item
        action.merge(path: helpers.instance_exec(item, &action[:block]))
      elsif action[:path].is_a?(Proc)
        # If path is a proc, evaluate it
        action.merge(path: action[:path].call(item))
      else
        action
      end
    end
  end
end