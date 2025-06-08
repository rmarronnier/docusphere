module Immo
  module Promo
    module Shared
      class AlertBannerComponent < ApplicationComponent
        def initialize(alerts:, type: 'warning', title: 'Alertes', icon: 'exclamation-triangle')
          @alerts = Array(alerts)
          @type = type
          @title = title
          @icon = icon
        end

        private

        attr_reader :alerts, :type, :title, :icon

        def type_classes
          case type
          when 'danger', 'critical'
            {
              bg: 'bg-red-50',
              border: 'border-red-200',
              title_color: 'text-red-800',
              icon_color: 'text-red-600',
              item_bg: 'bg-white',
              text_color: 'text-red-900',
              subtitle_color: 'text-red-700'
            }
          when 'warning'
            {
              bg: 'bg-yellow-50',
              border: 'border-yellow-200',
              title_color: 'text-yellow-800',
              icon_color: 'text-yellow-600',
              item_bg: 'bg-white',
              text_color: 'text-yellow-900',
              subtitle_color: 'text-yellow-700'
            }
          when 'info'
            {
              bg: 'bg-blue-50',
              border: 'border-blue-200',
              title_color: 'text-blue-800',
              icon_color: 'text-blue-600',
              item_bg: 'bg-white',
              text_color: 'text-blue-900',
              subtitle_color: 'text-blue-700'
            }
          else
            {
              bg: 'bg-gray-50',
              border: 'border-gray-200',
              title_color: 'text-gray-800',
              icon_color: 'text-gray-600',
              item_bg: 'bg-white',
              text_color: 'text-gray-900',
              subtitle_color: 'text-gray-700'
            }
          end
        end

        def styles
          @styles ||= type_classes
        end
      end
    end
  end
end