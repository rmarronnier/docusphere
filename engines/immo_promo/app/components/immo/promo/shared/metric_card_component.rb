module Immo
  module Promo
    module Shared
      class MetricCardComponent < ApplicationComponent
        def initialize(title:, value:, subtitle: nil, icon: 'chart-bar', icon_color: 'text-blue-600', trend: nil, trend_value: nil, bg_color: 'bg-white', value_color: 'text-gray-900')
          @title = title
          @value = value
          @subtitle = subtitle
          @icon = icon
          @icon_color = icon_color
          @trend = trend # :up, :down, :stable
          @trend_value = trend_value
          @bg_color = bg_color
          @value_color = value_color
        end

        private

        attr_reader :title, :value, :subtitle, :icon, :icon_color, :trend, :trend_value, :bg_color, :value_color

        def trend_icon
          case trend
          when :up
            'trending-up'
          when :down
            'trending-down'
          else
            'minus'
          end
        end

        def trend_color
          case trend
          when :up
            'text-green-600'
          when :down
            'text-red-600'
          else
            'text-gray-500'
          end
        end

        def formatted_value
          case value
          when Money
            value.format(symbol: true, thousands_separator: ' ')
          when Numeric
            number_with_delimiter(value)
          else
            value.to_s
          end
        end
      end
    end
  end
end