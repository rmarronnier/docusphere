# frozen_string_literal: true

module Immo
  module Promo
    class DashboardIntegrationComponent < ViewComponent::Base
      def initialize(user:, mode: :widgets)
        @user = user
        @mode = mode # :widgets or :standalone
        @projects = load_user_projects
        @dashboard_data = calculate_dashboard_data
      end

      private

      attr_reader :user, :mode, :projects, :dashboard_data

      def load_user_projects
        # Load active projects based on user profile - more efficient than widget component
        case user.active_profile&.profile_type
        when 'direction'
          Immo::Promo::Project.joins(:organization)
                              .where(organization: user.organization)
                              .active
                              .includes(:phases, :documents, :stakeholders, :permits)
                              .limit(10)
        when 'chef_projet'
          Immo::Promo::Project.where(project_manager: user)
                              .active
                              .includes(:phases, :documents, :stakeholders, :permits)
                              .limit(8)
        else
          user_stakeholder_projects = Immo::Promo::Stakeholder
                                       .where(user: user)
                                       .joins(:project)
                                       .select('immo_promo_projects.*')
          
          Immo::Promo::Project.where(id: user_stakeholder_projects.select(:project_id))
                              .active
                              .includes(:phases, :documents, :stakeholders)
                              .limit(6)
        end
      end

      def calculate_dashboard_data
        return default_dashboard_data if projects.empty?

        {
          projects_overview: projects_overview_data,
          documents_summary: documents_summary_data,
          workflow_status: workflow_status_data,
          recent_activity: recent_activity_data,
          alerts_summary: alerts_summary_data
        }
      end

      def default_dashboard_data
        {
          projects_overview: { total: 0, active: 0, delayed: 0 },
          documents_summary: { total: 0, pending: 0, approved: 0 },
          workflow_status: { on_track: 0, at_risk: 0, delayed: 0 },
          recent_activity: [],
          alerts_summary: { high: 0, medium: 0, low: 0 }
        }
      end

      def projects_overview_data
        {
          total: projects.count,
          active: projects.count(&:active?),
          delayed: projects.count(&:is_delayed?),
          completion_avg: projects.average { |p| p.completion_percentage }.to_f.round(1)
        }
      end

      def documents_summary_data
        all_documents = projects.flat_map(&:documents)
        
        {
          total: all_documents.count,
          pending: all_documents.count { |d| d.status.in?(['draft', 'under_review']) },
          approved: all_documents.count { |d| d.status == 'published' },
          this_week: all_documents.count { |d| d.created_at >= 1.week.ago }
        }
      end

      def workflow_status_data
        phases_data = projects.flat_map(&:phases)
        
        {
          on_track: phases_data.count { |p| p.status == 'completed' || (!p.is_delayed? && p.status == 'in_progress') },
          at_risk: phases_data.count { |p| p.status == 'in_progress' && near_deadline?(p) },
          delayed: phases_data.count { |p| p.is_delayed? }
        }
      end

      def recent_activity_data
        # Get recent activities across all user projects
        activities = []
        
        projects.each do |project|
          # Recent document uploads
          project.documents.where(created_at: 1.week.ago..Time.current).recent.limit(3).each do |doc|
            activities << {
              type: 'document_upload',
              title: "Document ajouté: #{doc.title}",
              project: project.name,
              time: doc.created_at,
              link: document_link(doc),
              icon: 'document',
              color: 'blue'
            }
          end
          
          # Phase completions
          project.phases.where(status: 'completed', updated_at: 1.week.ago..Time.current).each do |phase|
            activities << {
              type: 'phase_completion',
              title: "Phase terminée: #{phase.name}",
              project: project.name,
              time: phase.updated_at,
              link: project_link(project),
              icon: 'check-circle',
              color: 'green'
            }
          end
          
          # Permit updates
          project.permits.where(updated_at: 1.week.ago..Time.current).each do |permit|
            activities << {
              type: 'permit_update',
              title: "Permis mis à jour: #{permit.permit_type.humanize}",
              project: project.name,
              time: permit.updated_at,
              link: project_link(project),
              icon: 'clipboard-check',
              color: 'purple'
            }
          end
        end
        
        activities.sort_by { |a| a[:time] }.reverse.first(8)
      end

      def alerts_summary_data
        alerts = []
        
        projects.each do |project|
          # Document validation alerts
          pending_validations = project.documents.joins(:validation_requests)
                                       .where(validation_requests: { status: 'pending' })
                                       .count
          if pending_validations > 0
            alerts << { type: 'high', count: pending_validations, message: "Validations en attente" }
          end
          
          # Deadline alerts
          overdue_phases = project.phases.where('end_date < ? AND status != ?', Date.current, 'completed').count
          if overdue_phases > 0
            alerts << { type: 'high', count: overdue_phases, message: "Phases en retard" }
          end
          
          # Permit expiry alerts
          expiring_permits = project.permits.where(
            expiry_date: Date.current..30.days.from_now,
            status: 'approved'
          ).count
          if expiring_permits > 0
            alerts << { type: 'medium', count: expiring_permits, message: "Permis expirant sous 30j" }
          end
        end
        
        {
          high: alerts.count { |a| a[:type] == 'high' },
          medium: alerts.count { |a| a[:type] == 'medium' },
          low: alerts.count { |a| a[:type] == 'low' },
          details: alerts.first(5)
        }
      end

      def near_deadline?(phase)
        return false unless phase.end_date
        
        days_until_deadline = (phase.end_date - Date.current).to_i
        days_until_deadline <= 7 && days_until_deadline > 0
      end

      def project_link(project)
        helpers.immo_promo_engine.project_path(project)
      end

      def document_link(document)
        helpers.ged_document_path(document)
      end

      def time_ago_in_words_short(time)
        distance = Time.current - time
        
        case distance
        when 0..59.seconds
          'À l\'instant'
        when 1.minute..59.minutes
          "#{(distance / 1.minute).round}m"
        when 1.hour..23.hours
          "#{(distance / 1.hour).round}h"
        when 1.day..6.days
          "#{(distance / 1.day).round}j"
        when 1.week..3.weeks
          "#{(distance / 1.week).round}sem"
        else
          time.strftime('%d/%m')
        end
      end

      def activity_icon_class(icon)
        case icon
        when 'document' then 'text-blue-500'
        when 'check-circle' then 'text-green-500'
        when 'clipboard-check' then 'text-purple-500'
        when 'exclamation-triangle' then 'text-red-500'
        else 'text-gray-500'
        end
      end

      def alert_color_class(type)
        case type
        when 'high' then 'bg-red-100 text-red-800 border-red-200'
        when 'medium' then 'bg-yellow-100 text-yellow-800 border-yellow-200'
        when 'low' then 'bg-blue-100 text-blue-800 border-blue-200'
        else 'bg-gray-100 text-gray-800 border-gray-200'
        end
      end

      def show_project_documents_widget?
        mode == :widgets && projects.any? && user.active_profile&.profile_type.in?(['chef_projet', 'direction', 'commercial'])
      end

      def show_immo_alerts_widget?
        mode == :widgets && projects.any?
      end

      def show_standalone_dashboard?
        mode == :standalone
      end
    end
  end
end