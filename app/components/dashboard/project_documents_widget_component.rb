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
      return [] unless user.active_profile&.profile_type == 'chef_projet'

      # Charge les projets ImmoPromo assignés à l'utilisateur
      if defined?(Immo::Promo::Project)
        Immo::Promo::Project
          .joins(:project_stakeholders)
          .where(immo_promo_project_stakeholders: { stakeholder_id: user.id })
          .where(status: ['in_progress', 'planning', 'on_hold'])
          .order(updated_at: :desc)
          .limit(max_projects)
      else
        []
      end
    end

    def load_documents_by_project
      return {} if projects.empty?

      documents = {}
      projects.each do |project|
        # Documents liés au projet via association polymorphique
        project_docs = Document
          .where(documentable: project)
          .or(Document.where(space_id: project_space_id(project)))
          .includes(:uploaded_by, :tags)
          .order(created_at: :desc)
          .limit(5)

        documents[project.id] = {
          recent: project_docs,
          total_count: count_total_documents(project),
          pending_count: count_pending_documents(project),
          phase_breakdown: phase_document_breakdown(project)
        }
      end
      documents
    end

    def project_space_id(project)
      # Recherche l'espace GED associé au projet
      Space.find_by(name: "Projet #{project.name}")&.id
    end

    def count_total_documents(project)
      Document.where(documentable: project).count +
        Document.where(space_id: project_space_id(project)).count
    end

    def count_pending_documents(project)
      Document
        .where(documentable: project, status: ['draft', 'pending_validation'])
        .count
    end

    def phase_document_breakdown(project)
      return {} unless project.respond_to?(:phases)

      breakdown = {}
      project.phases.each do |phase|
        breakdown[phase.name] = Document
          .where(documentable: phase)
          .or(Document.where("metadata ->> 'phase_id' = ?", phase.id.to_s))
          .count
      end
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

      Document
        .where(documentable: projects)
        .where('created_at > ?', 7.days.ago)
        .count
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