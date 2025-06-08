module Immo
  module Promo
    module StakeholdersHelper
      def stakeholder_role_icon(role)
        case role&.to_s
        when 'architect'
          :blueprint
        when 'engineer'
          :cog
        when 'contractor'
          :hammer
        when 'project_manager'
          :user_group
        when 'technical_controller'
          :shield_check
        when 'safety_coordinator'
          :shield_exclamation
        when 'design_office'
          :academic_cap
        else
          :user
        end
      end

      def stakeholder_status_variant(status)
        case status&.to_s
        when 'pending'
          :warning
        when 'approved', 'active'
          :success
        when 'suspended'
          :danger
        when 'completed'
          :info
        else
          :secondary
        end
      end

      def stakeholder_status_text(status)
        case status&.to_s
        when 'pending'
          'En attente'
        when 'approved'
          'Approuvé'
        when 'active'
          'Actif'
        when 'suspended'
          'Suspendu'
        when 'completed'
          'Terminé'
        else
          'Inconnu'
        end
      end

      def stakeholder_role_options
        [
          ['Architecte', 'architect'],
          ['Ingénieur', 'engineer'],
          ['Entrepreneur', 'contractor'],
          ['Maître d\'œuvre', 'project_manager'],
          ['Contrôleur technique', 'technical_controller'],
          ['Coordinateur sécurité', 'safety_coordinator'],
          ['Bureau d\'études', 'design_office']
        ]
      end

      def qualification_level_options
        (1..5).map { |level| ["Niveau #{level}", level] }
      end

      def qualification_level_badge_class(level)
        case level
        when 1, 2
          'bg-red-100 text-red-800'
        when 3
          'bg-yellow-100 text-yellow-800'
        when 4, 5
          'bg-green-100 text-green-800'
        else
          'bg-gray-100 text-gray-800'
        end
      end

      def format_hourly_rate(rate)
        return '-' unless rate.present?
        "#{number_to_currency(rate, unit: '€', separator: ',', delimiter: ' ')}/h"
      end

      def format_daily_rate(rate)
        return '-' unless rate.present?
        "#{number_to_currency(rate, unit: '€', separator: ',', delimiter: ' ')}/jour"
      end

      def stakeholder_contract_status(stakeholder)
        return 'Aucun contrat' if stakeholder.contracts.empty?
        
        active_contracts = stakeholder.contracts.active
        return 'Contrat actif' if active_contracts.any?
        
        'Contrat inactif'
      end

      def stakeholder_certifications_status(stakeholder)
        return 'Aucune certification' if stakeholder.certifications.empty?
        
        valid_certifications = stakeholder.certifications.valid
        expired_certifications = stakeholder.certifications.expired
        
        if expired_certifications.any?
          'Certifications expirées'
        elsif valid_certifications.any?
          'Certifications valides'
        else
          'Certifications à vérifier'
        end
      end

      def stakeholder_activity_summary(stakeholder)
        tasks_count = stakeholder.assigned_tasks.count
        completed_tasks = stakeholder.assigned_tasks.completed.count
        
        return 'Aucune activité' if tasks_count.zero?
        
        completion_rate = (completed_tasks.to_f / tasks_count * 100).round
        "#{completed_tasks}/#{tasks_count} tâches (#{completion_rate}%)"
      end
    end
  end
end