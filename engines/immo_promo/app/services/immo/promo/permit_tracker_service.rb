module Immo
  module Promo
    class PermitTrackerService
      attr_reader :project, :current_user

      def initialize(project, current_user = nil)
        @project = project
        @current_user = current_user
        @timeline_service = PermitTimelineService.new(project)
        @compliance_service = RegulatoryComplianceService.new(project)
        @deadline_service = PermitDeadlineService.new(project)
      end

      # Délégation aux services spécialisés
      def track_permit_deadlines
        @deadline_service.track_permit_deadlines
      end

      def generate_permit_workflow
        @timeline_service.generate_permit_workflow
      end

      def check_regulatory_compliance
        @compliance_service.check_regulatory_compliance
      end

      def generate_permit_timeline
        @timeline_service.generate_permit_timeline
      end

      def calculate_processing_times
        @timeline_service.calculate_processing_times
      end

      def check_expiring_permits(days_threshold = 30)
        project.permits.expiring_soon(days_threshold).order(:expiry_date)
      end

      def compliance_check
        issues = @compliance_service.check_permit_conditions_compliance
        expired_permits = project.permits.approved.where('expiry_date < ?', Date.current)
        
        all_issues = []
        
        # Add permit condition issues
        issues.each do |issue|
          all_issues << {
            permit: issue[:permit],
            unmet_conditions: issue[:conditions]
          }
        end
        
        # Add expired permit issues
        expired_permits.each do |permit|
          all_issues << {
            permit: permit,
            issue_type: 'expired'
          }
        end
        
        {
          compliant: issues.empty? && expired_permits.empty?,
          issues: all_issues,
          expired_permits: expired_permits
        }
      end

      # Méthodes métier principales
      def track_permit_status
        total = project.permits.count
        by_status = project.permits.group(:status).count
        
        approved_count = by_status['approved'] || 0
        approval_rate = total > 0 ? (approved_count.to_f / total * 100).round(2) : 0
        
        {
          total: total,
          by_status: by_status.symbolize_keys,
          approval_rate: approval_rate,
          pending: project.permits.pending,
          approved: project.permits.approved,
          critical_pending: project.permits.critical.pending
        }
      end

      def critical_permits_status
        critical_types = ['construction', 'urban_planning']
        critical_permits = project.permits.where(permit_type: critical_types)
        
        approved_critical = critical_permits.approved.count
        total_critical = critical_permits.count
        
        {
          critical_permits: critical_permits,
          approved_count: approved_critical,
          total_count: total_critical,
          ready_for_construction: total_critical > 0 && approved_critical == total_critical,
          missing_permits: identify_missing_critical_permits(critical_types)
        }
      end

      def notify_permit_updates(permit, old_status, new_status)
        return unless old_status != new_status
        
        notification_data = build_permit_notification(permit, old_status, new_status)
        Notification.create!(notification_data)
        
        # Send email notification if critical status change
        if critical_status_change?(old_status, new_status)
          PermitMailer.status_change_notification(permit, old_status, new_status).deliver_later
        end
      end

      def generate_permit_report
        {
          project: {
            name: project.name,
            reference: project.reference_number
          },
          status_summary: track_permit_status,
          critical_permits: critical_permits_status,
          upcoming_deadlines: @deadline_service.upcoming_deadlines,
          overdue_items: @deadline_service.overdue_items,
          compliance: @compliance_service.compliance_summary,
          processing_times: calculate_processing_times,
          timeline: generate_permit_timeline,
          generated_at: Time.current
        }
      end

      def identify_bottlenecks
        bottlenecks = []
        
        # Permits under review for too long
        overdue_reviews = project.permits.overdue_response
        if overdue_reviews.any?
          bottlenecks << {
            type: :overdue_review,
            permits: overdue_reviews,
            message: "#{overdue_reviews.count} permis en attente de réponse depuis plus de 30 jours",
            severity: :high
          }
        end
        
        # Missing critical permits
        missing_critical = identify_missing_critical_permits(['construction', 'urban_planning'])
        if missing_critical.any?
          bottlenecks << {
            type: :missing_permits,
            permit_types: missing_critical,
            message: "Permis critiques manquants : #{missing_critical.join(', ')}",
            severity: :critical
          }
        end
        
        # Expiring permits without work started
        expiring_unused = project.permits.approved
                                         .expiring_soon(60)
                                         .joins(:project)
                                         .where(projects: { status: ['planning', 'permits'] })
        if expiring_unused.any?
          bottlenecks << {
            type: :expiring_unused,
            permits: expiring_unused,
            message: "#{expiring_unused.count} permis approuvés expirent bientôt sans travaux commencés",
            severity: :high
          }
        end
        
        bottlenecks
      end

      def suggest_next_actions
        actions = []
        
        # Check for permits needing submission
        draft_permits = project.permits.draft
        draft_permits.each do |permit|
          if permit.submission_urgency != :low
            actions << {
              type: :submit_permit,
              permit: permit,
              urgency: permit.submission_urgency,
              action: "Soumettre le #{permit.permit_type.humanize}",
              deadline: @deadline_service.send(:calculate_submission_deadline, permit)
            }
          end
        end
        
        # Check for overdue responses needing follow-up
        overdue_permits = project.permits.overdue_response
        overdue_permits.each do |permit|
          actions << {
            type: :follow_up,
            permit: permit,
            urgency: :high,
            action: "Relancer pour #{permit.permit_type.humanize}",
            overdue_days: permit.overdue_days
          }
        end
        
        # Check for expiring permits
        expiring_permits = project.permits.expiring_soon(30)
        expiring_permits.each do |permit|
          actions << {
            type: :use_or_extend,
            permit: permit,
            urgency: :critical,
            action: permit.expiry_action_required,
            days_remaining: permit.days_until_expiry
          }
        end
        
        actions.sort_by { |a| urgency_score(a[:urgency]) }.reverse
      end

      private

      def identify_missing_critical_permits(critical_types)
        existing_types = project.permits.pluck(:permit_type).uniq
        critical_types - existing_types
      end

      def build_permit_notification(permit, old_status, new_status)
        {
          title: "Changement de statut - #{permit.permit_type.humanize} #{permit.permit_number}",
          message: "Le permis #{permit.permit_number} est passé de #{old_status} à #{new_status}",
          notifiable: permit,
          user: project.project_manager || current_user || User.first,
          notification_type: 'system_announcement',
          data: {
            permit_id: permit.id,
            old_status: old_status,
            new_status: new_status,
            project_id: project.id
          }
        }
      end

      def critical_status_change?(old_status, new_status)
        critical_transitions = [
          ['submitted', 'approved'],
          ['submitted', 'denied'],
          ['under_review', 'approved'],
          ['under_review', 'denied'],
          ['appeal', 'approved'],
          ['appeal', 'denied']
        ]
        
        critical_transitions.include?([old_status, new_status])
      end

      def urgency_score(urgency)
        case urgency
        when :critical then 4
        when :high then 3
        when :medium then 2
        when :low then 1
        else 0
        end
      end
    end
  end
end