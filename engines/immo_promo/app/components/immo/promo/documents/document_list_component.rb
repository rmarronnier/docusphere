module Immo
  module Promo
    module Documents
      class DocumentListComponent < ViewComponent::Base
        def initialize(documents:, documentable:, current_user:, show_filters: true, show_stats: true)
          @documents = documents
          @documentable = documentable
          @current_user = current_user
          @show_filters = show_filters
          @show_stats = show_stats
        end

        private

        attr_reader :documents, :documentable, :current_user, :show_filters, :show_stats

        def can_upload?
          temp_document = ::Document.new(documentable: documentable)
          policy = Immo::Promo::DocumentPolicy.new(current_user, temp_document)
          policy.create?
        end

        def can_bulk_upload?
          temp_document = ::Document.new(documentable: documentable)
          policy = Immo::Promo::DocumentPolicy.new(current_user, temp_document)
          policy.bulk_upload?
        end

        def document_categories
          %w[project technical administrative financial legal permit plan environmental]
        end

        def document_statuses
          %w[draft published locked archived]
        end

        def documentable_name
          case documentable
          when Immo::Promo::Project
            "Projet #{documentable.name}"
          when Immo::Promo::Phase
            "Phase #{documentable.name}"
          when Immo::Promo::Task
            "Tâche #{documentable.name}"
          when Immo::Promo::Permit
            "Permis #{documentable.permit_name}"
          when Immo::Promo::Stakeholder
            "Intervenant #{documentable.name}"
          else
            documentable.to_s
          end
        end

        def upload_path
          case documentable
          when Immo::Promo::Project
            helpers.immo_promo_engine.project_documents_path(documentable)
          when Immo::Promo::Phase
            helpers.immo_promo_engine.phase_documents_path(documentable)
          when Immo::Promo::Task
            helpers.immo_promo_engine.task_documents_path(documentable)
          when Immo::Promo::Permit
            helpers.immo_promo_engine.permit_documents_path(documentable)
          when Immo::Promo::Stakeholder
            helpers.immo_promo_engine.stakeholder_documents_path(documentable)
          end
        end

        def bulk_upload_path
          case documentable
          when Immo::Promo::Project
            helpers.immo_promo_engine.bulk_upload_project_documents_path(documentable)
          when Immo::Promo::Phase
            helpers.immo_promo_engine.bulk_upload_phase_documents_path(documentable)
          when Immo::Promo::Task
            helpers.immo_promo_engine.bulk_upload_task_documents_path(documentable)
          when Immo::Promo::Permit
            helpers.immo_promo_engine.bulk_upload_permit_documents_path(documentable)
          when Immo::Promo::Stakeholder
            helpers.immo_promo_engine.bulk_upload_stakeholder_documents_path(documentable)
          end
        end

        def document_statistics
          @document_statistics ||= documentable.document_statistics
        end

        def workflow_status
          @workflow_status ||= documentable.document_workflow_status
        end

        def missing_documents
          @missing_documents ||= documentable.missing_critical_documents
        end

        def category_icon(category)
          case category
          when 'project'
            'folder'
          when 'technical'
            'wrench'
          when 'administrative'
            'clipboard'
          when 'financial'
            'currency-dollar'
          when 'legal'
            'scale'
          when 'permit'
            'document-check'
          when 'plan'
            'map'
          when 'environmental'
            'leaf'
          else
            'document'
          end
        end

        def status_color(status)
          case status
          when 'draft'
            'yellow'
          when 'published'
            'green'
          when 'locked'
            'red'
          when 'archived'
            'gray'
          else
            'blue'
          end
        end

        def format_file_size(size_in_bytes)
          return '0 B' if size_in_bytes.nil? || size_in_bytes.zero?
          
          units = ['B', 'KB', 'MB', 'GB']
          base = 1024
          exp = (Math.log(size_in_bytes) / Math.log(base)).to_i
          exp = [exp, units.length - 1].min
          
          "%.1f %s" % [size_in_bytes.to_f / (base ** exp), units[exp]]
        end

        def category_badge_color(category)
          case category
          when 'project'
            'blue'
          when 'technical'
            'purple'
          when 'administrative'
            'gray'
          when 'financial'
            'green'
          when 'legal'
            'red'
          when 'permit'
            'yellow'
          when 'plan'
            'indigo'
          when 'environmental'
            'emerald'
          else
            'slate'
          end
        end
      end
    end
  end
end