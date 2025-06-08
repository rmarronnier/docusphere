module Immo
  module Promo
    module Shared
      class StatusBadgeComponent < ApplicationComponent
        STATUSES = {
          # Project statuses
          planning: { color: 'blue', text: 'En planification' },
          in_progress: { color: 'green', text: 'En cours' },
          on_hold: { color: 'yellow', text: 'En pause' },
          completed: { color: 'gray', text: 'Terminé' },
          cancelled: { color: 'red', text: 'Annulé' },
          
          # Permit statuses
          draft: { color: 'gray', text: 'Brouillon' },
          submitted: { color: 'blue', text: 'Soumis' },
          under_review: { color: 'yellow', text: 'En révision' },
          approved: { color: 'green', text: 'Approuvé' },
          denied: { color: 'red', text: 'Refusé' },
          expired: { color: 'red', text: 'Expiré' },
          
          # Task statuses
          pending: { color: 'gray', text: 'En attente' },
          active: { color: 'green', text: 'Actif' },
          overdue: { color: 'red', text: 'En retard' },
          
          # Compliance statuses
          compliant: { color: 'green', text: 'Conforme' },
          warning: { color: 'yellow', text: 'Attention' },
          critical: { color: 'red', text: 'Critique' },
          valid: { color: 'green', text: 'Valide' },
          
          # Financial statuses
          on_track: { color: 'green', text: 'Dans les clous' },
          at_risk: { color: 'yellow', text: 'À risque' },
          over_budget: { color: 'red', text: 'Dépassement' }
        }.freeze

        def initialize(status:, size: 'default', custom_text: nil, extra_classes: nil)
          @status = status.to_sym
          @size = size
          @custom_text = custom_text
          @extra_classes = extra_classes
        end

        private

        attr_reader :status, :size, :custom_text, :extra_classes

        def status_config
          STATUSES[status] || { color: 'gray', text: status.to_s.humanize }
        end

        def badge_text
          custom_text || status_config[:text]
        end

        def color_classes
          color = status_config[:color]
          
          case color
          when 'red'
            'bg-red-100 text-red-800'
          when 'green'
            'bg-green-100 text-green-800'
          when 'blue'
            'bg-blue-100 text-blue-800'
          when 'yellow'
            'bg-yellow-100 text-yellow-800'
          when 'gray'
            'bg-gray-100 text-gray-800'
          else
            'bg-gray-100 text-gray-800'
          end
        end

        def size_classes
          case size
          when 'small', 'sm'
            'px-2 py-0.5 text-xs'
          when 'large', 'lg'
            'px-3 py-1 text-sm'
          else
            'px-2.5 py-0.5 text-xs'
          end
        end

        def badge_classes
          [
            'inline-flex items-center rounded-full font-medium',
            color_classes,
            size_classes,
            extra_classes
          ].compact.join(' ')
        end
      end
    end
  end
end