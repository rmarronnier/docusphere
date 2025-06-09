module Immo
  module Promo
    module Documents
      class BulkUploadComponent < ViewComponent::Base
        def initialize(documentable:, bulk_upload_path:)
          @documentable = documentable
          @bulk_upload_path = bulk_upload_path
        end

        private

        attr_reader :documentable, :bulk_upload_path

        def document_categories
          %w[project technical administrative financial legal permit plan environmental]
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

        def max_file_size_mb
          100
        end

        def max_files_count
          10
        end

        def accepted_file_extensions
          '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.jpg,.jpeg,.png,.gif,.webp,.txt'
        end
      end
    end
  end
end