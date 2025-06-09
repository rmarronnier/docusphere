class Ui::DataGridComponent::HeaderCellComponent < ApplicationComponent
  attr_reader :column, :current_sort_key, :current_sort_direction

  def initialize(column:, current_sort_key: nil, current_sort_direction: nil)
    @column = column
    @current_sort_key = current_sort_key
    @current_sort_direction = current_sort_direction
  end

  def call
    content_tag :th, 
                scope: "col",
                class: header_classes,
                role: "columnheader",
                style: column.width ? "width: #{column.width}" : nil,
                **sortable_attributes do
      content_tag :div, class: flex_classes do
        safe_join([
          column.label,
          column.sortable ? sort_indicator : nil
        ].compact)
      end
    end
  end

  private

  def header_classes
    classes = ["px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider"]
    
    classes << "cursor-pointer select-none hover:text-gray-700" if column.sortable
    
    case column.align
    when :center
      classes << "text-center"
    when :right
      classes << "text-right"
    else
      classes << "text-left"
    end
    
    classes << column.options[:header_class] if column.options[:header_class]
    classes.join(" ")
  end

  def flex_classes
    classes = ["flex items-center"]
    classes << "justify-center" if column.align == :center
    classes << "justify-end" if column.align == :right
    classes.join(" ")
  end

  def sortable_attributes
    return {} unless column.sortable
    
    {
      "data-sortable" => "true",
      "data-sort-key" => column.key,
      "data-action" => "click->data-grid#sort"
    }
  end

  def sort_indicator
    if column.key.to_s == current_sort_key.to_s
      # Show directional arrow for currently sorted column
      if current_sort_direction == "asc"
        ascending_arrow
      else
        descending_arrow
      end
    else
      # Show neutral sort indicator
      neutral_sort_indicator
    end
  end

  def neutral_sort_indicator
    content_tag :svg, class: "ml-1 h-4 w-4 text-gray-400", 
                fill: "none", 
                stroke: "currentColor", 
                viewBox: "0 0 24 24" do
      tag :path, "stroke-linecap": "round", 
          "stroke-linejoin": "round", 
          "stroke-width": "2", 
          d: "M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"
    end
  end

  def ascending_arrow
    content_tag :svg, class: "ml-1 h-4 w-4 text-gray-600", 
                fill: "none", 
                stroke: "currentColor", 
                viewBox: "0 0 24 24" do
      tag :path, "stroke-linecap": "round", 
          "stroke-linejoin": "round", 
          "stroke-width": "2", 
          d: "M5 15l7-7 7 7"
    end
  end

  def descending_arrow
    content_tag :svg, class: "ml-1 h-4 w-4 text-gray-600", 
                fill: "none", 
                stroke: "currentColor", 
                viewBox: "0 0 24 24" do
      tag :path, "stroke-linecap": "round", 
          "stroke-linejoin": "round", 
          "stroke-width": "2", 
          d: "M19 9l-7 7-7-7"
    end
  end
end