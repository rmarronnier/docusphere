module Immo
  module Promo
    module Shared
      class ProgressIndicatorComponent < ApplicationComponent
        def initialize(progress:, status: nil, show_label: true, size: 'default', color_scheme: 'auto')
          @progress = [progress.to_f, 100].min
          @status = status
          @show_label = show_label
          @size = size
          @color_scheme = color_scheme
        end

        private

        attr_reader :progress, :status, :show_label, :size, :color_scheme

        def progress_color
          return manual_color if color_scheme != 'auto'
          
          if status.present?
            case status.to_s
            when 'on_track', 'completed', 'approved'
              'bg-green-600'
            when 'at_risk', 'warning', 'pending'
              'bg-yellow-600'
            when 'critical', 'overdue', 'denied'
              'bg-red-600'
            else
              'bg-blue-600'
            end
          else
            # Color based on percentage
            if progress >= 80
              'bg-green-600'
            elsif progress >= 60
              'bg-blue-600'
            elsif progress >= 40
              'bg-yellow-600'
            else
              'bg-red-600'
            end
          end
        end

        def manual_color
          case color_scheme
          when 'green'
            'bg-green-600'
          when 'blue'
            'bg-blue-600'
          when 'yellow'
            'bg-yellow-600'
          when 'red'
            'bg-red-600'
          else
            'bg-gray-600'
          end
        end

        def height_class
          case size
          when 'small', 'sm'
            'h-1.5'
          when 'large', 'lg'
            'h-3'
          else
            'h-2'
          end
        end

        def formatted_progress
          "#{progress.round}%"
        end
      end
    end
  end
end