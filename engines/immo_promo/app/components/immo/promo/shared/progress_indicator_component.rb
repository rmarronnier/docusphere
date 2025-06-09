module Immo
  module Promo
    module Shared
      class ProgressIndicatorComponent < ::Ui::ProgressBarComponent
        def initialize(progress:, status: nil, show_label: true, size: 'default', color_scheme: 'auto')
          # Map size to parent component's size system
          size_mapped = case size
                        when 'small', 'sm' then :small
                        when 'large', 'lg' then :large
                        else :medium
                        end
          
          # Determine color based on status or color_scheme
          color = determine_color(progress, status, color_scheme)
          
          # Call parent initializer
          super(
            value: progress,
            max: 100,
            size: size_mapped,
            color: color,
            show_label: show_label
          )
          
          @status = status
        end

        private

        attr_reader :status

        def determine_color(progress, status, color_scheme)
          return color_scheme.to_sym if color_scheme != 'auto'
          
          if status.present?
            case status.to_s
            when 'on_track', 'completed', 'approved'
              :green
            when 'at_risk', 'warning', 'pending'
              :yellow
            when 'critical', 'overdue', 'denied'
              :red
            else
              :blue
            end
          else
            # Use parent's auto color logic
            :auto
          end
        end

        # Override the auto_color_class to match ImmoPromo's thresholds
        def auto_color_class
          case @percentage
          when 0..40 then 'bg-red-600'
          when 41..60 then 'bg-yellow-600'
          when 61..80 then 'bg-blue-600'
          else 'bg-green-600'
          end
        end
      end
    end
  end
end