module Immo
  module Promo
    class StakeholderCoordinatorService
      attr_reader :project, :current_user

      def initialize(project, current_user = nil)
        @project = project
        @current_user = current_user
        @notification_service = StakeholderNotificationService.new(project, current_user)
        @engagement_service = StakeholderEngagementService.new(project)
        @qualification_service = StakeholderQualificationService.new(project)
        @allocation_service = StakeholderAllocationService.new(project)
      end

      # Délégation aux services spécialisés
      def organize_stakeholders_by_role
        result = {}
        
        Immo::Promo::Stakeholder.stakeholder_types.keys.each do |type|
          result[type] = project.stakeholders.where(stakeholder_type: type).to_a
        end
        
        result
      end

      def notify_stakeholders(message, options = {})
        @notification_service.notify_stakeholders(message, options)
      end

      def generate_contact_sheet(active_only: false)
        @engagement_service.generate_contact_sheet(active_only: active_only)
      end

      def track_stakeholder_engagement(stakeholder = nil)
        @engagement_service.track_stakeholder_engagement(stakeholder)
      end

      def identify_key_stakeholders
        @engagement_service.identify_key_stakeholders
      end

      def coordination_matrix
        @engagement_service.coordination_matrix
      end

      def check_all_qualifications
        @qualification_service.check_all_qualifications
      end

      def check_contract_compliance
        @qualification_service.check_contract_compliance
      end

      def schedule_coordination_meeting(stakeholder_ids, meeting_details)
        @notification_service.schedule_coordination_meeting(stakeholder_ids, meeting_details)
      end

      def optimize_team_allocation
        @allocation_service.optimize_team_allocation
      end

      def suggest_stakeholder_for_task(task)
        @allocation_service.suggest_stakeholder_for_task(task)
      end

      def coordinate_interventions
        @allocation_service.coordinate_interventions
      end

      # Méthode principale pour générer un rapport complet
      def generate_stakeholder_report
        by_type = {}
        Immo::Promo::Stakeholder.stakeholder_types.keys.each do |type|
          by_type[type] = project.stakeholders.where(stakeholder_type: type).count
        end
        
        {
          project: {
            name: project.name,
            reference: project.reference_number
          },
          total_stakeholders: project.stakeholders.count,
          by_type: by_type,
          active_count: project.stakeholders.active.count,
          engagement_summary: track_stakeholder_engagement,
          key_stakeholders: identify_key_stakeholders,
          contact_sheet: generate_contact_sheet,
          generated_at: Time.current
        }
      end
    end
  end
end