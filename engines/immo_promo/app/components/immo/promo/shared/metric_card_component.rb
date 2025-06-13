module Immo
  module Promo
    module Shared
      class MetricCardComponent < ApplicationComponent
        def initialize(title:, value:, subtitle: nil, icon: 'chart-bar', icon_color: 'text-blue-600', 
                       trend: nil, trend_value: nil, bg_color: 'bg-white', value_color: 'text-gray-900',
                       format: :auto, clickable: false, url: nil, size: :default, **options)
          @title = title
          @value = value
          @subtitle = subtitle
          @icon = icon
          @icon_color = icon_color
          @trend = trend # :up, :down, :stable
          @trend_value = trend_value
          @bg_color = bg_color
          @value_color = value_color
          @format = format # :auto, :money, :number, :percentage, :none
          @clickable = clickable
          @url = url
          @size = size # :small, :default, :large
          @options = options
        end

        private

        attr_reader :title, :value, :subtitle, :icon, :icon_color, :trend, :trend_value, 
                    :bg_color, :value_color, :format, :clickable, :url, :size, :options

        def render_content
          render Ui::MetricCardComponent.new(
            title: title,
            value: value,
            subtitle: enhanced_subtitle,
            icon: project_specific_icon,
            icon_color: project_specific_icon_color,
            trend: trend,
            trend_value: trend_value,
            bg_color: project_specific_bg_color,
            value_color: project_specific_value_color,
            format: format,
            class: card_size_classes
          )
        end

        def enhanced_subtitle
          return subtitle unless subtitle.present?
          
          # Add project context to subtitle for better dashboard display
          case title.downcase
          when /budget/, /coût/, /dépense/
            "#{subtitle} • Projets immobiliers"
          when /projet/, /construction/
            "#{subtitle} • En cours"
          else
            subtitle
          end
        end

        def project_specific_icon
          # Map common project metrics to appropriate icons
          case title.downcase
          when /budget/, /coût/, /financ/
            'currency-euro'
          when /projet/, /développement/
            'office-building'
          when /logement/, /unité/
            'home'
          when /surface/, /m²/
            'rectangle-group'
          when /avancement/, /progress/, /pourcentage/
            'chart-bar'
          when /délai/, /retard/
            'clock'
          when /risque/, /alerte/
            'exclamation-triangle'
          else
            icon
          end
        end

        def project_specific_icon_color
          # Context-aware colors for project metrics
          case title.downcase
          when /budget/, /coût/
            value_indicates_problem? ? 'text-red-600' : 'text-green-600'
          when /retard/, /délai/
            'text-orange-600'
          when /risque/, /alerte/
            'text-red-600'
          when /avancement/, /progress/
            progress_color
          else
            icon_color
          end
        end

        def project_specific_bg_color
          return bg_color unless clickable
          
          case bg_color
          when 'bg-white'
            'bg-white hover:bg-gray-50'
          else
            "#{bg_color} hover:opacity-90"
          end
        end

        def project_specific_value_color
          return value_color unless value_indicates_problem?
          
          case title.downcase
          when /budget/, /coût/
            'text-red-600 font-semibold'
          when /retard/, /délai/
            'text-orange-600 font-semibold'
          else
            value_color
          end
        end

        def value_indicates_problem?
          return false unless value.is_a?(Numeric)
          
          case title.downcase
          when /budget/, /coût/
            # Problem if over 100% for budget usage
            format == :percentage && value > 100
          when /retard/, /délai/
            # Problem if positive (days delayed)
            value > 0
          when /risque/
            # Problem if high risk count
            value > 2
          else
            false
          end
        end

        def progress_color
          return 'text-blue-600' unless value.is_a?(Numeric)
          
          case value
          when 0..25
            'text-red-600'
          when 26..50
            'text-orange-600'
          when 51..75
            'text-blue-600'
          else
            'text-green-600'
          end
        end

        def card_size_classes
          case size
          when :small
            'text-sm'
          when :large
            'text-lg'
          else
            ''
          end
        end

        # Helper methods for common project metrics
        def self.budget_metric(total_budget:, current_budget:, **options)
          usage_percentage = total_budget && current_budget && total_budget.amount > 0 ? 
                           (current_budget.amount.to_f / total_budget.amount * 100).round(1) : 0
          
          new(
            title: 'Utilisation Budget',
            value: usage_percentage,
            subtitle: "#{current_budget&.format || '0 €'} / #{total_budget&.format || '0 €'}",
            format: :percentage,
            trend: usage_percentage > 100 ? :up : (usage_percentage > 75 ? :stable : :down),
            **options
          )
        end

        def self.progress_metric(completion_percentage:, **options)
          new(
            title: 'Avancement Global',
            value: completion_percentage,
            subtitle: 'Moyenne des projets',
            format: :percentage,
            trend: completion_percentage > 75 ? :up : (completion_percentage > 50 ? :stable : :down),
            **options
          )
        end

        def self.project_count_metric(active_count:, total_count:, **options)
          new(
            title: 'Projets Actifs',
            value: active_count,
            subtitle: "#{total_count} au total",
            format: :number,
            **options
          )
        end
      end
    end
  end
end