module Immo
  module Promo
    module Shared
      class StatusBadgeComponent < ::Ui::StatusBadgeComponent
        # Override PRESETS with French translations and ImmoPromo-specific statuses
        PRESETS = {
          # Project statuses
          planning: { color: :blue, label: 'En planification' },
          in_progress: { color: :green, label: 'En cours' },
          on_hold: { color: :yellow, label: 'En pause' },
          completed: { color: :gray, label: 'Terminé' },
          cancelled: { color: :red, label: 'Annulé' },
          
          # Permit statuses
          draft: { color: :gray, label: 'Brouillon' },
          submitted: { color: :blue, label: 'Soumis' },
          under_review: { color: :yellow, label: 'En révision' },
          approved: { color: :green, label: 'Approuvé' },
          denied: { color: :red, label: 'Refusé' },
          expired: { color: :red, label: 'Expiré' },
          
          # Task statuses
          pending: { color: :gray, label: 'En attente' },
          active: { color: :green, label: 'Actif' },
          overdue: { color: :red, label: 'En retard' },
          
          # Compliance statuses
          compliant: { color: :green, label: 'Conforme' },
          warning: { color: :yellow, label: 'Attention' },
          critical: { color: :red, label: 'Critique' },
          valid: { color: :green, label: 'Valide' },
          
          # Financial statuses
          on_track: { color: :green, label: 'Dans les clous' },
          at_risk: { color: :yellow, label: 'À risque' },
          over_budget: { color: :red, label: 'Dépassement' }
        }.freeze

        def initialize(status:, size: 'default', custom_text: nil, extra_classes: nil)
          # Map size to parent component's size system
          size_mapped = case size
                        when 'small', 'sm' then :small
                        when 'large', 'lg' then :large
                        else :medium
                        end
          
          # Call parent initializer with mapped parameters
          super(status: status, label: custom_text, size: size_mapped)
          
          @extra_classes = extra_classes
        end

        private

        attr_reader :extra_classes

        def badge_classes
          # Get parent classes and add any extra classes
          parent_classes = super
          [parent_classes, extra_classes].compact.join(' ')
        end
      end
    end
  end
end