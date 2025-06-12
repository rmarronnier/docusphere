# frozen_string_literal: true

module Immo
  module Promo
    class ProjectDocumentsDashboardWidgetComponent < ViewComponent::Base
      def initialize(user:, limit: 5)
        @user = user
        @limit = limit
        @projects = load_user_projects
        @documents_stats = calculate_documents_stats
      end

      private

      attr_reader :user, :limit, :projects, :documents_stats

      def load_user_projects
        # Get projects the user is involved with based on their profile
        case user.active_profile&.profile_type
        when 'direction'
          # Direction sees all active projects
          Immo::Promo::Project.joins(:organization)
                              .where(organization: user.organization)
                              .active
                              .includes(:phases, :documents, :stakeholders)
                              .limit(limit)
        when 'chef_projet'
          # Project managers see their assigned projects
          Immo::Promo::Project.where(project_manager: user)
                              .active
                              .includes(:phases, :documents, :stakeholders)
                              .limit(limit)
        when 'commercial'
          # Commercial users see projects with sales/marketing stakeholders
          user_stakeholder_projects = Immo::Promo::Stakeholder
                                       .where(user: user, role: ['sales', 'marketing'])
                                       .joins(:project)
                                       .select('immo_promo_projects.*')
          
          Immo::Promo::Project.where(id: user_stakeholder_projects.select(:project_id))
                              .active
                              .includes(:phases, :documents, :stakeholders)
                              .limit(limit)
        else
          # Default: projects where user is a stakeholder
          user_stakeholder_projects = Immo::Promo::Stakeholder
                                       .where(user: user)
                                       .joins(:project)
                                       .select('immo_promo_projects.*')
          
          Immo::Promo::Project.where(id: user_stakeholder_projects.select(:project_id))
                              .active
                              .includes(:phases, :documents, :stakeholders)
                              .limit(limit)
        end
      end

      def calculate_documents_stats
        return { total_projects: 0, total_documents: 0, pending_documents: 0, recent_uploads: 0 } if projects.empty?

        {
          total_projects: projects.count,
          total_documents: projects.sum { |p| p.documents.count },
          pending_documents: projects.sum { |p| p.documents.where(status: ['draft', 'under_review']).count },
          recent_uploads: projects.sum { |p| p.documents.where(created_at: 1.week.ago..Time.current).count }
        }
      end

      def documents_by_project
        @documents_by_project ||= projects.each_with_object({}) do |project, hash|
          project_docs = project.documents.includes(:file_attachment, :tags, :uploaded_by).recent.limit(5)
          
          hash[project.id] = {
            total_count: project.documents.count,
            recent: project_docs,
            phase_breakdown: phase_breakdown_for_project(project),
            categories_breakdown: categories_breakdown_for_project(project)
          }
        end
      end

      def phase_breakdown_for_project(project)
        breakdown = {}
        
        project.phases.includes(:documents).each do |phase|
          phase_docs_count = project.documents.joins(:metadata)
                                   .where(metadata: { key: 'phase_id', value: phase.id.to_s })
                                   .count
          
          if phase_docs_count > 0
            breakdown[phase.name] = phase_docs_count
          end
        end
        
        # Add documents not assigned to any phase
        unassigned_count = project.documents.left_joins(:metadata)
                                  .where.not(metadata: { key: 'phase_id' })
                                  .or(project.documents.where(metadata: { id: nil }))
                                  .count
        
        breakdown['Non assignés'] = unassigned_count if unassigned_count > 0
        
        breakdown
      end

      def categories_breakdown_for_project(project)
        project.documents.group(:document_category).count
      end

      def has_urgent_documents?(project)
        # Check for documents requiring immediate attention
        project.documents.where(status: 'under_review')
               .joins(:validation_requests)
               .where(validation_requests: { status: 'pending', priority: 'high' })
               .exists? ||
        project.documents.where(status: 'draft')
               .where('created_at < ?', 3.days.ago)
               .exists?
      end

      def project_status_color(status)
        case status
        when 'planning' then 'bg-blue-100 text-blue-800'
        when 'pre_construction' then 'bg-yellow-100 text-yellow-800'
        when 'construction' then 'bg-orange-100 text-orange-800'
        when 'finishing' then 'bg-purple-100 text-purple-800'
        when 'delivered' then 'bg-green-100 text-green-800'
        when 'completed' then 'bg-gray-100 text-gray-800'
        when 'cancelled' then 'bg-red-100 text-red-800'
        else 'bg-gray-100 text-gray-600'
        end
      end

      def project_status_label(status)
        case status
        when 'planning' then 'Planification'
        when 'pre_construction' then 'Pré-construction'
        when 'construction' then 'Construction'
        when 'finishing' then 'Finitions'
        when 'delivered' then 'Livré'
        when 'completed' then 'Terminé'
        when 'cancelled' then 'Annulé'
        else status.humanize
        end
      end

      def current_phase_name(project)
        current_phase = project.phases.where(status: 'in_progress').first ||
                       project.phases.where(status: 'pending').first
        current_phase&.name || 'Aucune phase active'
      end

      def project_progress_percentage(project)
        project.completion_percentage.to_i
      end

      def phase_color(index)
        colors = %w[blue green purple orange red indigo pink]
        colors[index % colors.length]
      end

      def project_documents_path(project)
        helpers.immo_promo_engine.project_documents_path(project)
      end

      def upload_document_path(project)
        # Use the route helper that was added for project document upload
        helpers.upload_document_path(project)
      end
    end
  end
end