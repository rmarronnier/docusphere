module Immo
  module Promo
    module Coordination
      class InterventionCardComponent < ViewComponent::Base
        attr_reader :intervention, :variant, :show_progress, :show_timeline, :size, :extra_classes

        def initialize(intervention:, variant: :default, show_progress: true, show_timeline: false, size: :medium, extra_classes: nil)
          @intervention = intervention
          @variant = variant.to_sym
          @show_progress = show_progress
          @show_timeline = show_timeline
          @size = size.to_sym
          @extra_classes = extra_classes
        end

        private

        def card_classes
          base_classes = "border rounded-lg p-3 bg-white hover:shadow-md transition-shadow"
          variant_classes = case variant
                          when :current
                            "border-green-200 bg-green-50"
                          when :upcoming
                            "border-blue-200 bg-blue-50"
                          when :overdue
                            "border-red-200 bg-red-50"
                          when :completed
                            "border-gray-200 bg-gray-50"
                          else
                            "border-gray-200"
                          end
          
          size_classes = case size
                        when :small
                          "p-2 text-sm"
                        when :large
                          "p-4"
                        else
                          "p-3"
                        end
          
          [base_classes, variant_classes, size_classes, extra_classes].compact.join(" ")
        end

        def intervention_status_color
          case intervention.status
          when 'completed'
            'text-green-600'
          when 'in_progress'
            'text-blue-600'
          when 'blocked'
            'text-red-600'
          when 'pending'
            'text-yellow-600'
          else
            'text-gray-600'
          end
        end

        def intervention_status_text
          case intervention.status
          when 'completed'
            'Terminée'
          when 'in_progress'
            'En cours'
          when 'blocked'
            'Bloquée'
          when 'pending'
            'En attente'
          else
            intervention.status.humanize
          end
        end

        def priority_badge_color
          case intervention.priority
          when 'critical'
            'bg-red-100 text-red-800'
          when 'high'
            'bg-orange-100 text-orange-800'
          when 'medium'
            'bg-yellow-100 text-yellow-800'
          when 'low'
            'bg-gray-100 text-gray-800'
          else
            'bg-gray-100 text-gray-800'
          end
        end

        def priority_text
          case intervention.priority
          when 'critical'
            'Critique'
          when 'high'
            'Élevée'
          when 'medium'
            'Moyenne'
          when 'low'
            'Faible'
          else
            intervention.priority.humanize
          end
        end

        def format_date(date)
          return 'Non définie' unless date
          
          case variant
          when :current, :upcoming
            l(date, format: :short)
          else
            l(date, format: :long)
          end
        end

        def format_date_with_status(date)
          return format_date(date) unless date
          
          days_diff = (date.to_date - Date.current).to_i
          formatted_date = format_date(date)
          
          case days_diff
          when 0
            "#{formatted_date} (Aujourd'hui)"
          when 1
            "#{formatted_date} (Demain)"
          when -1
            "#{formatted_date} (Hier)"
          when (2..7)
            "#{formatted_date} (Dans #{days_diff} jours)"
          when (-7..-2)
            "#{formatted_date} (Il y a #{-days_diff} jours)"
          when (8..30)
            "#{formatted_date} (Dans #{days_diff} jours)"
          when (-30..-8)
            "#{formatted_date} (Il y a #{-days_diff} jours)"
          else
            formatted_date
          end
        end

        def display_date
          case variant
          when :current
            intervention.end_date ? format_date_with_status(intervention.end_date) : 'Échéance non définie'
          when :upcoming
            intervention.start_date ? format_date_with_status(intervention.start_date) : 'Début non défini'
          else
            intervention.start_date ? format_date(intervention.start_date) : format_date(intervention.end_date)
          end
        end

        def display_date_label
          case variant
          when :current
            'Échéance'
          when :upcoming
            'Début prévu'
          else
            'Date'
          end
        end

        def assigned_person_name
          intervention.assigned_to&.display_name || intervention.stakeholder&.name || 'Non assigné'
        end

        def phase_name
          intervention.phase&.name || 'Phase non définie'
        end

        def task_type_icon
          case intervention.task_type
          when 'planning'
            'calendar'
          when 'execution'
            'cog-8-tooth'
          when 'review'
            'eye'
          when 'approval'
            'check-circle'
          when 'milestone'
            'flag'
          when 'administrative'
            'document-text'
          when 'technical'
            'wrench-screwdriver'
          else
            'clipboard-document-list'
          end
        end

        def task_type_text
          case intervention.task_type
          when 'planning'
            'Planification'
          when 'execution'
            'Exécution'
          when 'review'
            'Révision'
          when 'approval'
            'Approbation'
          when 'milestone'
            'Jalon'
          when 'administrative'
            'Administratif'
          when 'technical'
            'Technique'
          else
            intervention.task_type.humanize
          end
        end

        def progress_color_scheme
          case intervention.status
          when 'completed'
            'green'
          when 'in_progress'
            'blue'
          when 'blocked'
            'red'
          else
            'gray'
          end
        end

        def is_overdue?
          intervention.respond_to?(:is_overdue?) ? intervention.is_overdue? : false
        end

        def days_remaining
          intervention.respond_to?(:days_remaining) ? intervention.days_remaining : nil
        end

        def timeline_items
          return [] unless show_timeline
          
          items = []
          
          if intervention.start_date
            items << {
              date: intervention.start_date,
              label: 'Début',
              status: Date.current >= intervention.start_date.to_date ? 'completed' : 'pending'
            }
          end
          
          if intervention.end_date
            items << {
              date: intervention.end_date,
              label: 'Fin prévue',
              status: intervention.status == 'completed' ? 'completed' : 
                     (Date.current > intervention.end_date.to_date ? 'overdue' : 'pending')
            }
          end
          
          items.sort_by { |item| item[:date] }
        end

        def required_skills
          if intervention.respond_to?(:required_skills) && intervention.required_skills.present?
            intervention.required_skills.is_a?(Array) ? intervention.required_skills : [intervention.required_skills]
          else
            []
          end
        end

        def completion_percentage
          intervention.respond_to?(:completion_percentage) ? intervention.completion_percentage : 0
        end
      end
    end
  end
end