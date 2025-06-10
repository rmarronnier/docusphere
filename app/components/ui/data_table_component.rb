class Ui::DataTableComponent < BaseTableComponent
  attr_reader :items, :columns, :responsive, :striped, :hoverable, :empty_message
  
  def initialize(items: nil, columns: nil, responsive: true, striped: false, hoverable: false, empty_message: nil, **options)
    super(
      items: items || [],
      columns: columns || [],
      responsive: responsive,
      striped: striped,
      hoverable: hoverable,
      empty_message: empty_message || "No data available",
      **options
    )
  end

  # Override base method for custom cell rendering
  def cell_value(item, column)
    return yield(item, column) if block_given?
    
    value = extract_value(item, column[:key])
    
    case column[:type]
    when :status
      render Ui::StatusBadgeComponent.new(
        status: value,
        label: column[:label]
      )
    when :progress
      render Ui::ProgressBarComponent.new(
        value: value,
        show_label: false,
        size: :small
      )
    when :money
      format_money(value)
    when :date
      l(value, format: column[:format] || :short) if value
    when :datetime
      l(value, format: column[:format] || :long) if value
    when :link
      link_to value, column[:path].call(item), class: 'text-blue-600 hover:text-blue-700'
    when :custom
      column[:render].call(item, value)
    else
      value.to_s
    end
  end

  def extract_value(item, key)
    return nil unless key
    
    if key.is_a?(Proc)
      key.call(item)
    elsif key.is_a?(String) && key.include?('.')
      key.split('.').reduce(item) { |obj, method| 
        if obj.respond_to?(method)
          obj.public_send(method)
        elsif obj.respond_to?(:[])
          obj[method] || obj[method.to_sym]
        else
          nil
        end
      }
    elsif item.respond_to?(key)
      item.public_send(key)
    elsif item.respond_to?(:[])
      item[key] || item[key.to_s]
    else
      nil
    end
  end

  def format_money(value)
    return '-' unless value
    
    if value.respond_to?(:format)
      value.format(symbol: true, thousands_separator: ' ')
    else
      helpers.number_to_currency(value, unit: '€', separator: ',', delimiter: ' ')
    end
  end

  # Check if we should render the advanced table format
  def advanced_mode?
    columns.present?
  end
  
  def render_advanced_table
    if items.any?
      table_html = '<table class="' + table_classes + '">'
      
      # Header
      table_html << '<thead class="bg-gray-50"><tr>'
      columns.each do |column|
        table_html << "<th scope=\"col\" class=\"px-3 py-3.5 text-left text-sm font-semibold text-gray-900 #{column[:class]}\">#{column[:label]}</th>"
      end
      if content.present?
        table_html << '<th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6"><span class="sr-only">Actions</span></th>'
      end
      table_html << '</tr></thead>'
      
      # Body
      table_html << '<tbody class="divide-y divide-gray-200 bg-white">'
      items.each do |item|
        table_html << '<tr class="' + (hoverable ? 'hover:bg-gray-50' : '') + '">'
        columns.each do |column|
          table_html << "<td class=\"whitespace-nowrap px-3 py-4 text-sm #{column[:td_class]}\">#{cell_value(item, column)}</td>"
        end
        if content.present?
          table_html << '<td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">' + content.to_s + '</td>'
        end
        table_html << '</tr>'
      end
      table_html << '</tbody></table>'
      
      table_html.html_safe
    else
      "<div class=\"text-center py-12\"><p class=\"text-sm text-gray-500\">#{empty_message}</p></div>".html_safe
    end
  end
end