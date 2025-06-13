class Ui::DataGridComponent::HeaderCellComponent < ApplicationComponent
  attr_reader :column, :current_sort_key, :current_sort_direction

  def initialize(column:, current_sort_key: nil, current_sort_direction: nil)
    @column = column
    @current_sort_key = current_sort_key
    @current_sort_direction = current_sort_direction
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

end