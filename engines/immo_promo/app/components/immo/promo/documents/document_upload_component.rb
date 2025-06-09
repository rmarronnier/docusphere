module Immo
  module Promo
    module Documents
      class DocumentUploadComponent < ViewComponent::Base
        def initialize(documentable:, upload_path:)
          @documentable = documentable
          @upload_path = upload_path
        end

        private

        attr_reader :documentable, :upload_path

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

        def category_description(category)
          case category
          when 'project'
            'Documents généraux du projet'
          when 'technical'
            'Plans techniques, spécifications, dessins'
          when 'administrative'
            'Courriers, autorisations, correspondances'
          when 'financial'
            'Budgets, factures, devis'
          when 'legal'
            'Contrats, accords, documents juridiques'
          when 'permit'
            'Permis, autorisations administratives'
          when 'plan'
            'Plans d\'architecte, plans de masse'
          when 'environmental'
            'Études environnementales, impact écologique'
          else
            'Documents divers'
          end
        end

        def max_file_size_mb
          100
        end

        def accepted_file_types
          [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp',
            'text/plain'
          ]
        end

        def accepted_file_extensions
          '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.jpg,.jpeg,.png,.gif,.webp,.txt'
        end
      end
    end
  end
end