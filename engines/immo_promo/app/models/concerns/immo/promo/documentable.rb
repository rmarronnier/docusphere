module Immo
  module Promo
    module Documentable
      extend ActiveSupport::Concern
      
      # Include the main Documentable concern from the app
      include ::Documentable

      included do
        # All associations are already defined in the main Documentable concern
        # We can add Immo::Promo specific customizations here if needed
      end

      # Override to use DocumentIntegrationService specific to ImmoPromo
      def attach_document(file, category: 'project', user:, title: nil, description: nil)
        document = super
        
        # Use ImmoPromo specific integration service if available
        if defined?(Immo::Promo::DocumentIntegrationService)
          Immo::Promo::DocumentIntegrationService.new(document, self).process_document
        end
        
        document
      end

      # ImmoPromo specific: Share documents with stakeholders
      def share_documents_with_stakeholder(stakeholder, document_ids, permission_level: 'read', user:)
        shares = []
        document_ids.each do |doc_id|
          document = documents.find(doc_id)
          share = document.document_shares.create!(
            shared_with: stakeholder.respond_to?(:user) ? stakeholder.user : nil,
            email: stakeholder.email,
            access_level: permission_level,
            shared_by: user,
            expires_at: 30.days.from_now
          )
          shares << share
        end
        shares
      end

      def share_document_category_with_stakeholders(category, stakeholders, permission_level: 'read', user:)
        document_ids = documents_by_category(category).pluck(:id)
        shares = []
        stakeholders.each do |stakeholder|
          shares.concat(share_documents_with_stakeholder(stakeholder, document_ids, permission_level: permission_level, user: user))
        end
        shares
      end
    end
  end
end