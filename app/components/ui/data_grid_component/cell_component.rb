class Ui::DataGridComponent::CellComponent < ApplicationComponent
  attr_reader :item, :column, :value, :compact

  def initialize(item:, column:, value: nil, compact: false)
    @item = item
    @column = column
    @value = value || extract_value
    @compact = compact
  end


  private

  def extract_value
    item.try(column.key) || item[column.key]
  end

  def formatted_value
    format_value(value, column.format)
  end

  def format_value(value, format)
    return value unless format
    
    case format
    when :currency
      helpers.number_to_currency(value)
    when :percentage
      helpers.number_to_percentage(value, precision: 1)
    when :date
      value.strftime("%Y-%m-%d") if value.respond_to?(:strftime)
    when :datetime
      value.strftime("%Y-%m-%d %H:%M") if value.respond_to?(:strftime)
    when :boolean
      value ? "✓" : "✗"
    when Proc
      format.call(value)
    else
      value
    end
  end

  def cell_classes
    classes = ["px-6 whitespace-nowrap text-sm"]
    
    classes << (compact ? "py-2" : "py-4")
    
    case column.align
    when :center
      classes << "text-center"
    when :right
      classes << "text-right"
    else
      classes << "text-left"
    end
    
    classes << column.options[:cell_class] if column.options[:cell_class]
    classes.join(" ")
  end
end