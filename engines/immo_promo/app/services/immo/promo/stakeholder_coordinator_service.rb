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
      
      def count_stakeholders_by_role
        result = {}
        
        Immo::Promo::Stakeholder.stakeholder_types.keys.each do |type|
          result[type] = project.stakeholders.where(stakeholder_type: type).count
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
        active_tasks = @allocation_service.active_interventions
        upcoming_tasks = @allocation_service.upcoming_interventions
        
        {
          success: true,
          coordination_plan: build_coordination_plan(active_tasks),
          conflicts: detect_conflicts,
          optimization_suggestions: @allocation_service.optimization_suggestions,
          current_interventions: active_tasks,
          upcoming_interventions: upcoming_tasks
        }
      end

      def check_certifications
        qualifications = @qualification_service.check_all_qualifications
        
        {
          success: true,
          compliance_status: {
            compliant: qualifications[:summary][:fully_qualified],
            non_compliant: qualifications[:summary][:total_stakeholders] - qualifications[:summary][:fully_qualified],
            warning: 0
          },
          expiring_soon: [],
          critical_issues: qualifications[:issues].select { |i| i[:severity] == :critical },
          stakeholder_details: build_certification_details
        }
      end

      def generate_coordination_report
        {
          success: true,
          report: {
            summary: build_report_summary,
            stakeholder_overview: @engagement_service.stakeholder_overview,
            task_distribution: @allocation_service.task_distribution,
            performance_metrics: @engagement_service.performance_metrics,
            issues_and_risks: @qualification_service.coordination_risks,
            recommendations: @allocation_service.recommendations
          },
          generated_at: Time.current,
          generated_by: @current_user
        }
      end

      def generate_stakeholder_report
        {
          project: {
            name: project.name,
            reference: project.reference_number
          },
          total_stakeholders: project.stakeholders.count,
          by_type: count_stakeholders_by_role,
          active_count: project.stakeholders.active.count,
          engagement_summary: track_stakeholder_engagement,
          key_stakeholders: identify_key_stakeholders,
          contact_sheet: generate_contact_sheet,
          generated_at: Time.current
        }
      end

      def active_interventions
        @allocation_service.active_interventions
      end

      def detect_conflicts
        @allocation_service.detect_conflicts
      end

      def analyze_stakeholder_performance(stakeholder)
        @engagement_service.analyze_performance(stakeholder)
      end

      def optimize_resource_allocation
        @allocation_service.optimize_resource_allocation
      end

      def forecast_completion
        @allocation_service.forecast_completion
      end

      def send_coordination_alerts
        @notification_service.send_coordination_alerts
      end

      def generate_ai_recommendations
        {
          recommendations: {
            resource_optimization: @allocation_service.resource_recommendations,
            schedule_improvements: @allocation_service.schedule_recommendations,
            risk_mitigation: @qualification_service.risk_recommendations,
            cost_savings: []
          }
        }
      end

      private

      def build_coordination_plan(tasks)
        tasks.group_by { |t| t.start_date }.map do |date, date_tasks|
          {
            date: date,
            stakeholder: date_tasks.first.stakeholder,
            tasks: date_tasks.map { |t| { id: t.id, name: t.name, phase: t.phase.name } },
            duration: date_tasks.sum(&:estimated_hours)
          }
        end
      end

      def build_report_summary
        {
          project_name: project.name,
          status: project.status,
          progress: project.calculate_overall_progress,
          stakeholder_count: project.stakeholders.count,
          active_tasks: project.tasks.where(status: ['pending', 'in_progress']).count
        }
      end

      def build_certification_details
        project.stakeholders.includes(:certifications).map do |stakeholder|
          {
            stakeholder: stakeholder,
            certifications: stakeholder.certifications,
            expired: stakeholder.certifications.where('expiry_date < ?', Date.current),
            expiring_soon: stakeholder.certifications.where('expiry_date BETWEEN ? AND ?', Date.current, Date.current + 30.days),
            missing: @qualification_service.missing_certifications_for(stakeholder),
            status: @qualification_service.stakeholder_status(stakeholder)
          }
        end
      end
    end
  end
end