class Ui::DataGridComponent < ApplicationComponent
  renders_many :columns, lambda { |key:, label:, sortable: false, width: nil, align: :left, format: nil, **options|
    {
      key: key,
      label: label,
      sortable: sortable,
      width: width,
      align: align,
      format: format,
      options: options
    }
  }
  
  renders_one :empty_state
  renders_many :actions, lambda { |item, **options|
    content_tag(:div, class: "flex items-center space-x-2") do
      yield(item)
    end
  }

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

  def header_cell_classes(column)
    classes = ["px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider"]
    classes << "cursor-pointer select-none hover:text-gray-700" if column[:sortable]
    
    case column[:align]
    when :center
      classes << "text-center"
    when :right
      classes << "text-right"
    else
      classes << "text-left"
    end
    
    classes << column[:options][:header_class] if column[:options][:header_class]
    classes.join(" ")
  end

  def body_cell_classes(column)
    classes = ["px-6 whitespace-nowrap text-sm"]
    classes << "py-4" unless compact
    classes << "py-2" if compact
    
    case column[:align]
    when :center
      classes << "text-center"
    when :right
      classes << "text-right"
    else
      classes << "text-left"
    end
    
    classes << column[:options][:cell_class] if column[:options][:cell_class]
    classes.join(" ")
  end

  def row_classes(index)
    classes = []
    classes << "bg-gray-50" if striped && index.odd?
    classes << "hover:bg-gray-50" if hover
    classes << "cursor-pointer" if options[:row_click]
    classes.join(" ")
  end

  def format_value(value, format)
    return value unless format
    
    case format
    when :currency
      number_to_currency(value)
    when :percentage
      number_to_percentage(value, precision: 1)
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

  def loading_rows
    5.times.map do
      content_tag(:tr) do
        columns.size.times.map do
          content_tag(:td, class: body_cell_classes({})) do
            content_tag(:div, nil, class: "h-4 bg-gray-200 rounded animate-pulse")
          end
        end.join.html_safe
      end
    end.join.html_safe
  end
end