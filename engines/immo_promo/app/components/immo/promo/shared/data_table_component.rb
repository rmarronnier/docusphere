module Immo
  module Promo
    module Shared
      class DataTableComponent < ::Ui::DataTableComponent
        def initialize(items:, columns:, actions: nil, empty_message: 'Aucune donnée disponible', striped: true, hoverable: true, responsive: true)
          # Call parent initializer with translated empty message
          super(
            items: items,
            columns: columns,
            responsive: responsive,
            striped: striped,
            hoverable: hoverable,
            empty_message: empty_message
          )
          
          @actions = actions
        end

        private

        attr_reader :actions

        # Override render_cell to handle ImmoPromo-specific status component
        def render_cell(item, column)
          value = extract_value(item, column[:key])
          
          case column[:type]
          when :status
            # Use ImmoPromo's StatusBadgeComponent for French labels
            render Immo::Promo::Shared::StatusBadgeComponent.new(
              status: value,
              custom_text: column[:label]
            )
          when :progress
            # Use ImmoPromo's ProgressIndicatorComponent
            render Immo::Promo::Shared::ProgressIndicatorComponent.new(
              progress: value,
              show_label: false,
              size: 'small'
            )
          else
            # Delegate to parent for other types
            super
          end
        end
      end
    end
  end
end