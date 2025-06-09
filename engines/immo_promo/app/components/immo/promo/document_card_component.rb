module Immo
  module Promo
    class DocumentCardComponent < ViewComponent::Base
      attr_reader :document, :documentable, :show_actions
      
      def initialize(document:, documentable:, show_actions: true)
        @document = document
        @documentable = documentable
        @show_actions = show_actions
      end
      
      def document_icon
        case document.file.content_type
        when /pdf/
          { 
            path: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z",
            color: "text-red-500"
          }
        when /image/
          {
            path: "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z",
            color: "text-green-500"
          }
        when /word|document/
          {
            path: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
            color: "text-blue-500"
          }
        when /sheet|excel/
          {
            path: "M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2",
            color: "text-green-600"
          }
        else
          {
            path: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
            color: "text-gray-500"
          }
        end
      end
      
      def status_badge
        if document.status == 'draft'
          { text: 'Brouillon', classes: 'bg-gray-100 text-gray-700' }
        elsif document.validation_requests.pending.any?
          { text: 'En validation', classes: 'bg-yellow-100 text-yellow-700' }
        elsif document.validation_requests.approved.any?
          { text: 'Approuvé', classes: 'bg-green-100 text-green-700' }
        else
          nil
        end
      end
      
      def preview_path
        helpers.immo_promo_engine.preview_project_document_path(documentable, document)
      end
      
      def download_path
        helpers.immo_promo_engine.download_project_document_path(documentable, document)
      end
      
      def share_path
        helpers.immo_promo_engine.share_project_document_path(documentable, document)
      end
      
      def show_path
        helpers.immo_promo_engine.project_document_path(documentable, document)
      end
      
      def file_size
        helpers.number_to_human_size(document.file.byte_size)
      end
      
      def upload_date
        helpers.l(document.created_at, format: :short)
      end
      
      def category_label
        I18n.t("document.categories.#{document.document_category}", 
               default: document.document_category.humanize)
      end
    end
  end
end