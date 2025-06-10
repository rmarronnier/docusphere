# Base component for all table-based components
class BaseTableComponent < ApplicationComponent
  include Accessible

  def initialize(items:, columns:, **options)
    @items = items
    @columns = columns
    @options = options
    @selectable = options.fetch(:selectable, false)
    @striped = options.fetch(:striped, true)
    @bordered = options.fetch(:bordered, true)
    @hoverable = options.fetch(:hoverable, true)
    @responsive = options.fetch(:responsive, true)
    @empty_message = options[:empty_message]
    @loading = options.fetch(:loading, false)
    @sortable = options.fetch(:sortable, false)
    @current_sort = options[:current_sort]
    @sort_direction = options.fetch(:sort_direction, 'asc')
  end

  protected

  def table_classes
    classes = ['min-w-full divide-y divide-gray-200']
    classes << 'striped' if @striped
    classes << 'bordered' if @bordered
    classes << 'hoverable' if @hoverable
    classes.join(' ')
  end

  def wrapper_classes
    return 'overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg' unless @responsive
    'overflow-x-auto'
  end

  def render_header
    content_tag :thead, class: 'bg-gray-50' do
      content_tag :tr do
        safe_join([
          render_selection_header,
          @columns.map { |column| render_header_cell(column) }
        ].flatten.compact)
      end
    end
  end

  def render_body
    content_tag :tbody, class: 'bg-white divide-y divide-gray-200' do
      if @items.any?
        safe_join(@items.map.with_index { |item, index| render_row(item, index) })
      else
        render_empty_state
      end
    end
  end

  def render_header_cell(column)
    content_tag :th, 
                scope: 'col',
                class: header_cell_classes(column) do
      if @sortable && column[:sortable] != false
        render_sortable_header(column)
      else
        column[:label] || column[:key].to_s.humanize
      end
    end
  end

  def render_sortable_header(column)
    # Override in subclasses to implement sorting
    column[:label] || column[:key].to_s.humanize
  end

  def render_row(item, index)
    content_tag :tr, class: row_classes(item, index) do
      safe_join([
        render_selection_cell(item),
        @columns.map { |column| render_cell(item, column) }
      ].flatten.compact)
    end
  end

  def render_cell(item, column)
    content_tag :td, class: cell_classes(column) do
      cell_value(item, column)
    end
  end

  def cell_value(item, column)
    # Override in subclasses for custom rendering
    value = item.respond_to?(column[:key]) ? item.public_send(column[:key]) : nil
    value || '-'
  end

  def render_empty_state
    content_tag :tr do
      content_tag :td, 
                  colspan: total_columns,
                  class: 'px-6 py-4 text-center text-sm text-gray-500' do
        @empty_message || t('components.table.empty', default: 'No data available')
      end
    end
  end

  def render_selection_header
    return unless @selectable
    
    content_tag :th, scope: 'col', class: 'relative px-6 py-3' do
      content_tag :input,
                  nil,
                  type: 'checkbox',
                  class: 'absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500',
                  data: { action: 'change->bulk-actions#toggleAll' }
    end
  end

  def render_selection_cell(item)
    return unless @selectable
    
    content_tag :td, class: 'relative px-6 py-4' do
      content_tag :input,
                  nil,
                  type: 'checkbox',
                  value: item_identifier(item),
                  class: 'absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500',
                  data: { action: 'change->bulk-actions#toggle' }
    end
  end

  def item_identifier(item)
    item.respond_to?(:id) ? item.id : item.object_id
  end

  def total_columns
    count = @columns.size
    count += 1 if @selectable
    count
  end

  def header_cell_classes(column)
    classes = ['px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider']
    classes << column[:class] if column[:class]
    classes.join(' ')
  end

  def cell_classes(column)
    classes = ['px-6 py-4 whitespace-nowrap text-sm text-gray-900']
    classes << column[:cell_class] if column[:cell_class]
    classes.join(' ')
  end

  def row_classes(item, index)
    classes = []
    classes << 'bg-gray-50' if @striped && index.odd?
    classes << 'hover:bg-gray-100' if @hoverable
    classes.join(' ')
  end
end