# frozen_string_literal: true

module Dashboard
  class ProjectDocumentsWidgetComponent < ViewComponent::Base
    include Turbo::FramesHelper

    def initialize(user:, max_projects: 5)
      @user = user
      @max_projects = max_projects
      @projects = load_user_projects
      @documents_by_project = load_documents_by_project
      @stats = calculate_stats
    end

    private

    attr_reader :user, :max_projects, :projects, :documents_by_project, :stats

    def load_user_projects
      # Load projects based on user profile - supporting multiple profile types
      return [] unless user.active_profile
      
      if defined?(Immo::Promo::Project)
        case user.active_profile.profile_type
        when 'chef_projet'
          # Project managers see their assigned projects
          Immo::Promo::Project
            .where(project_manager: user)
            .active
            .includes(:phases, :documents, :stakeholders)
            .order(updated_at: :desc)
            .limit(max_projects)
        when 'direction'
          # Direction sees all active projects in their organization
          Immo::Promo::Project
            .joins(:organization)
            .where(organization: user.organization)
            .active
            .includes(:phases, :documents, :stakeholders)
            .order(updated_at: :desc)
            .limit(max_projects)
        when 'commercial'
          # Commercial users see projects where they are stakeholders
          user_stakeholder_projects = Immo::Promo::Stakeholder
                                       .where(user: user, role: ['sales', 'marketing'])
                                       .joins(:project)
                                       .select('immo_promo_projects.*')
          
          Immo::Promo::Project
            .where(id: user_stakeholder_projects.select(:project_id))
            .active
            .includes(:phases, :documents, :stakeholders)
            .limit(max_projects)
        else
          []
        end
      else
        []
      end
    end

    def load_documents_by_project
      return {} if projects.empty?

      documents = {}
      projects.each do |project|
        # Documents liés au projet via association polymorphique (utilise Documentable)
        project_docs = project.documents
                             .includes(:uploaded_by, :tags, :file_attachment)
                             .order(created_at: :desc)
                             .limit(5)

        documents[project.id] = {
          recent: project_docs,
          total_count: project.documents.count,
          pending_count: project.documents.where(status: ['draft', 'under_review']).count,
          phase_breakdown: phase_document_breakdown(project)
        }
      end
      documents
    end

    def project_space_id(project)
      # Recherche l'espace GED associé au projet
      Space.find_by(name: "Projet #{project.name}")&.id
    end

    def phase_document_breakdown(project)
      return {} unless project.respond_to?(:phases)

      breakdown = {}
      project.phases.includes(:documents).each do |phase|
        phase_docs_count = phase.documents.count
        breakdown[phase.name] = phase_docs_count if phase_docs_count > 0
      end
      
      # Add documents not assigned to any phase
      unassigned_count = project.documents.where.missing(:metadata)
                               .or(project.documents.left_joins(:metadata)
                                         .where.not(metadata: { key: 'phase_id' }))
                               .count
      
      breakdown['Non assignés'] = unassigned_count if unassigned_count > 0
      breakdown
    end

    def calculate_stats
      {
        total_projects: projects.count,
        total_documents: documents_by_project.values.sum { |d| d[:total_count] },
        pending_documents: documents_by_project.values.sum { |d| d[:pending_count] },
        recent_uploads: count_recent_uploads
      }
    end

    def count_recent_uploads
      return 0 if projects.empty?

      projects.sum { |project| project.documents.where('created_at > ?', 7.days.ago).count }
    end

    def project_status_color(status)
      case status
      when 'in_progress' then 'text-green-600 bg-green-100'
      when 'planning' then 'text-blue-600 bg-blue-100'
      when 'on_hold' then 'text-yellow-600 bg-yellow-100'
      when 'completed' then 'text-gray-600 bg-gray-100'
      else 'text-gray-600 bg-gray-100'
      end
    end

    def project_status_label(status)
      case status
      when 'in_progress' then 'En cours'
      when 'planning' then 'Planification'
      when 'on_hold' then 'En pause'
      when 'completed' then 'Terminé'
      else status.humanize
      end
    end

    def document_type_icon(document)
      return 'file' unless document.respond_to?(:file_content_type)

      case document.file_content_type
      when /pdf/ then 'file-pdf'
      when /word|docx/ then 'file-word'
      when /excel|xlsx/ then 'file-excel'
      when /powerpoint|pptx/ then 'file-powerpoint'
      when /image/ then 'file-image'
      when /video/ then 'file-video'
      when /zip|rar/ then 'file-archive'
      else 'file'
      end
    end

    def current_phase_name(project)
      return 'Non définie' unless project.respond_to?(:current_phase)

      project.current_phase&.name || 'Initialisation'
    end

    def project_progress_percentage(project)
      return 0 unless project.respond_to?(:completion_percentage)

      project.completion_percentage || 0
    end

    def upload_document_path(project)
      helpers.new_ged_document_path(
        documentable_type: 'Immo::Promo::Project',
        documentable_id: project.id
      )
    end

    def project_documents_path(project)
      helpers.ged_documents_path(
        documentable_type: 'Immo::Promo::Project',
        documentable_id: project.id
      )
    end

    def has_urgent_documents?(project)
      documents_by_project[project.id][:pending_count] > 0
    end

    def phase_colors
      %w[blue green purple pink yellow indigo red orange]
    end

    def phase_color(index)
      colors = phase_colors
      colors[index % colors.length]
    end
  end
end