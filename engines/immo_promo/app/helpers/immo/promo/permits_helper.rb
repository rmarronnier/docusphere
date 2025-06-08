module Immo
  module Promo
    module PermitsHelper
      def permit_type_icon(permit_type)
        case permit_type&.to_s
        when 'building_permit'
          :building
        when 'prior_declaration'
          :document
        when 'demolition_permit'
          :hammer
        when 'development_permit'
          :map
        when 'work_authorization'
          :wrench
        when 'urban_certificate'
          :clipboard
        else
          :document
        end
      end

      def permit_type_label(permit_type)
        case permit_type&.to_s
        when 'building_permit'
          'Permis de construire'
        when 'prior_declaration'
          'Déclaration préalable'
        when 'demolition_permit'
          'Permis de démolir'
        when 'development_permit'
          'Permis d\'aménager'
        when 'work_authorization'
          'Autorisation de travaux'
        when 'urban_certificate'
          'Certificat d\'urbanisme'
        else
          permit_type&.humanize || 'Non défini'
        end
      end

      def permit_status_variant(status)
        case status&.to_s
        when 'draft'
          :secondary
        when 'submitted'
          :info
        when 'under_review'
          :warning
        when 'approved'
          :success
        when 'rejected'
          :danger
        when 'expired'
          :danger
        else
          :secondary
        end
      end

      def permit_status_text(status)
        case status&.to_s
        when 'draft'
          'Brouillon'
        when 'submitted'
          'Soumis'
        when 'under_review'
          'En cours d\'examen'
        when 'approved'
          'Approuvé'
        when 'rejected'
          'Rejeté'
        when 'expired'
          'Expiré'
        else
          'Inconnu'
        end
      end

      def permit_type_options
        [
          ['Permis de construire', 'building_permit'],
          ['Déclaration préalable', 'prior_declaration'],
          ['Permis de démolir', 'demolition_permit'],
          ['Permis d\'aménager', 'development_permit'],
          ['Autorisation de travaux', 'work_authorization'],
          ['Certificat d\'urbanisme', 'urban_certificate']
        ]
      end

      def permit_expiry_warning_class(expiry_date)
        return 'text-gray-400 mr-1' unless expiry_date.present?
        
        days_until_expiry = (expiry_date - Date.current).to_i
        
        case days_until_expiry
        when -Float::INFINITY..0
          'text-red-500 mr-1' # Expiré
        when 1..30
          'text-orange-500 mr-1' # Expire bientôt
        else
          'text-gray-400 mr-1' # Normal
        end
      end

      def permit_expiry_text_class(expiry_date)
        return 'text-gray-500' unless expiry_date.present?
        
        days_until_expiry = (expiry_date - Date.current).to_i
        
        case days_until_expiry
        when -Float::INFINITY..0
          'text-red-600' # Expiré
        when 1..30
          'text-orange-600' # Expire bientôt
        else
          'text-gray-600' # Normal
        end
      end

      def condition_status_variant(status)
        case status&.to_s
        when 'pending'
          :warning
        when 'completed'
          :success
        when 'overdue'
          :danger
        else
          :secondary
        end
      end

      def condition_status_text(status)
        case status&.to_s
        when 'pending'
          'En attente'
        when 'completed'
          'Remplie'
        when 'overdue'
          'En retard'
        else
          'Inconnu'
        end
      end

      def format_deadline_remaining(deadline)
        return 'Aucune échéance' unless deadline.present?
        
        days_remaining = (deadline - Date.current).to_i
        
        case days_remaining
        when -Float::INFINITY..-1
          "En retard de #{days_remaining.abs} jour#{'s' if days_remaining.abs > 1}"
        when 0
          "Échéance aujourd'hui"
        when 1
          "Demain"
        when 2..7
          "Dans #{days_remaining} jours"
        when 8..30
          "Dans #{days_remaining} jours"
        else
          "Le #{l(deadline, format: :short)}"
        end
      end

      def permit_progress_percentage(permit)
        return 0 unless permit.conditions.any?
        
        total_conditions = permit.conditions.count
        completed_conditions = permit.conditions.where(status: 'completed').count
        
        (completed_conditions.to_f / total_conditions * 100).round
      end

      def permit_urgency_score(permit)
        score = 0
        
        # Score basé sur l'expiration
        if permit.expiry_date.present?
          days_until_expiry = (permit.expiry_date - Date.current).to_i
          score += case days_until_expiry
                  when -Float::INFINITY..0 then 100
                  when 1..7 then 80
                  when 8..30 then 60
                  when 31..90 then 40
                  else 20
                  end
        end
        
        # Score basé sur les conditions en retard
        overdue_conditions = permit.conditions.select { |c| c.deadline.present? && c.deadline < Date.current && c.status != 'completed' }
        score += overdue_conditions.count * 20
        
        # Score basé sur le statut
        score += case permit.status
                when 'submitted', 'under_review' then 30
                when 'approved' then -20
                else 0
                end
        
        [score, 100].min
      end

      def permit_urgency_badge_class(urgency_score)
        case urgency_score
        when 0..20
          'bg-green-100 text-green-800'
        when 21..40
          'bg-yellow-100 text-yellow-800'
        when 41..60
          'bg-orange-100 text-orange-800'
        else
          'bg-red-100 text-red-800'
        end
      end

      def permit_urgency_text(urgency_score)
        case urgency_score
        when 0..20
          'Faible'
        when 21..40
          'Modérée'
        when 41..60
          'Élevée'
        else
          'Critique'
        end
      end

      def format_permit_cost(cost)
        return 'Gratuit' if cost.nil? || cost.zero?
        number_to_currency(cost, unit: '€', separator: ',', delimiter: ' ')
      end

      def permit_completion_status_text(permit)
        progress = permit_progress_percentage(permit)
        
        case progress
        when 0
          'Non commencé'
        when 1..30
          'En cours'
        when 31..70
          'Avancement'
        when 71..99
          'Presque terminé'
        when 100
          'Terminé'
        end
      end
    end
  end
end