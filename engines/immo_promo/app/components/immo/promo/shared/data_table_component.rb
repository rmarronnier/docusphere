module Immo
  module Promo
    module Shared
      class DataTableComponent < BaseListComponent
        def initialize(items:, columns:, actions: nil, empty_message: 'Aucune donnée disponible', striped: true, hoverable: true, responsive: true)
          @items = items
          @columns = columns
          @actions = actions
          @empty_message = empty_message
          @striped = striped
          @hoverable = hoverable
          @responsive = responsive
        end

        private

        attr_reader :items, :columns, :actions, :empty_message, :striped, :hoverable, :responsive

        def table_classes
          classes = ['min-w-full divide-y divide-gray-300']
          classes << 'table-striped' if striped
          classes << 'table-hover' if hoverable
          classes.join(' ')
        end

        def render_cell(item, column)
          value = extract_value(item, column[:key])
          
          case column[:type]
          when :status
            render Ui::StatusBadgeComponent.new(
              status: value,
              preset: column[:preset] || 'default'
            )
          when :progress
            render Immo::Promo::Shared::ProgressIndicatorComponent.new(
              progress: value,
              show_label: false,
              size: 'small'
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
          if key.is_a?(Symbol)
            item.public_send(key)
          elsif key.is_a?(String) && key.include?('.')
            key.split('.').reduce(item) { |obj, method| obj&.public_send(method) }
          elsif key.is_a?(Proc)
            key.call(item)
          else
            item[key]
          end
        end

        def format_money(value)
          return '-' unless value
          
          if value.respond_to?(:format)
            value.format(symbol: true, thousands_separator: ' ')
          else
            number_to_currency(value, unit: '€', separator: ',', delimiter: ' ')
          end
        end
      end
    end
  end
end