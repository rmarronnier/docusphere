# frozen_string_literal: true

module Documents
  module FileManagement
    extend ActiveSupport::Concern

    included do
      has_one_attached :file
      has_one_attached :preview
      has_one_attached :thumbnail
      has_one_attached :preview_medium
      
      validates :file, presence: true, unless: :skip_file_validation
      validates :file_size, numericality: { less_than_or_equal_to: 100.megabytes }, if: :file_attached?
      
      attr_accessor :skip_file_validation
    end

    # File validation helper
    def file_attached?
      file.attached?
    end

    # Get file size in bytes
    def file_size
      file.blob.byte_size if file.attached?
    end

    def file_extension
      return nil unless file.attached?
      File.extname(file.filename.to_s).downcase
    end

    def file_name_without_extension
      return nil unless file.attached?
      File.basename(file.filename.to_s, file_extension)
    end

    def human_file_size
      return nil unless file_size
      
      if file_size < 1024
        "#{file_size} B"
      elsif file_size < 1024 * 1024
        "#{(file_size / 1024.0).round(1)} KB"
      elsif file_size < 1024 * 1024 * 1024
        "#{(file_size / (1024.0 * 1024)).round(1)} MB"
      else
        "#{(file_size / (1024.0 * 1024 * 1024)).round(2)} GB"
      end
    end

    # Get file content type
    def file_content_type
      if file.attached?
        file.blob.content_type
      else
        content_type
      end
    end
    
    # Thumbnail status helpers (requis par tests)
    def has_thumbnail?
      thumbnail.attached?
    end
    
    def thumbnail_generation_failed?
      thumbnail_generation_status == 'failed'
    end
    
    # File type helpers
    def pdf?
      file_content_type == 'application/pdf'
    end
    
    def image?
      file_content_type&.start_with?('image/')
    end
    
    def video?
      file_content_type&.start_with?('video/')
    end
    
    def office_document?
      office_mime_types.include?(file_content_type)
    end
    
    def supported_format?
      pdf? || image? || video? || office_document?
    end
    
    def text?
      return false unless file.attached?
      
      text_types = ['text/plain', 'text/html', 'text/css', 'text/javascript', 'text/markdown']
      text_types.include?(file_content_type) || code_file?
    end
    
    def code_file?
      return false unless file.attached?
      
      code_extensions = %w[.rb .js .py .java .c .cpp .h .css .scss .json .xml .yaml .yml .sh .sql]
      code_extensions.include?(file_extension)
    end
    
    def content_type_category
      return :pdf if pdf?
      return :image if image?
      return :video if video?
      return :office if office_document?
      return :text if text?
      return :cad if cad_file?
      return :archive if archive_file?
      :unknown
    end
    
    def cad_file?
      return false unless file.attached?
      
      cad_types = ['application/acad', 'application/x-acad', 'application/autocad_dwg', 
                   'image/x-dwg', 'application/dwg', 'application/x-dwg', 'application/x-autocad']
      cad_extensions = %w[.dwg .dxf .dwf]
      
      cad_types.include?(file_content_type) || cad_extensions.include?(file_extension)
    end
    
    def archive_file?
      return false unless file.attached?
      
      archive_types = ['application/zip', 'application/x-zip-compressed', 'application/x-rar-compressed',
                       'application/x-tar', 'application/x-gzip', 'application/gzip']
      archive_extensions = %w[.zip .rar .tar .gz .7z .bz2]
      
      archive_types.include?(file_content_type) || archive_extensions.include?(file_extension)
    end
    
    def previewable?
      supported_format? || text?
    end
    
    def thumbnail_url
      return nil unless has_thumbnail?
      Rails.application.routes.url_helpers.rails_blob_path(thumbnail)
    end
    
    def preview_url(variant = :large)
      return nil unless preview.attached?
      Rails.application.routes.url_helpers.rails_blob_path(preview)
    end
    
    def part_of_collection?
      parent_id.present? || children.any?
    end
    
    def collection_index
      return 0 unless parent_id.present?
      parent.children.order(:created_at).pluck(:id).index(id) || 0
    end
    
    def collection_count
      if parent_id.present?
        parent.children.count
      else
        children.count + 1
      end
    end
    
    def office_viewable?
      office_document? && publicly_accessible?
    end
    
    def publicly_accessible?
      # This would check if the document has a public URL
      # For now, return false as we don't have public URLs implemented
      false
    end
    
    def public_url
      # Would return a public URL for the document
      # For Office Online Viewer integration
      nil
    end
    
    def preview_pages
      # Would return an array of preview page attachments
      # For multi-page documents
      []
    end
    
    def current_version
      versions.last
    end
    
    def versioned?
      versions.any?
    end
    
    def related_documents
      # Would return documents that are related based on various criteria
      # For now, return documents from the same folder
      Document.where(folder_id: folder_id).where.not(id: id).limit(10)
    end
    
    def metadata_values
      # Return metadata as a hash
      metadata_hash = {}
      metadata.each do |m|
        metadata_hash[m.key] = m.value
      end
      metadata_hash
    end
    
    def activities
      # Would return activity log entries
      # For now, return audits as a proxy
      audits
    end
    
    def project_linked?
      documentable_type == 'Immo::Promo::Project' && documentable_id.present?
    end
    
    def contract?
      document_type_classification == 'contract' || 
        title.downcase.include?('contrat') ||
        file_name_without_extension&.downcase&.include?('contrat')
    end
    
    def plan?
      document_type_classification == 'plan' ||
        title.downcase.include?('plan') ||
        cad_file?
    end
    
    def pricing_document?
      document_type_classification == 'pricing' ||
        title.downcase.match?(/devis|tarif|prix|pricing/)
    end
    
    def client_visible?
      # Check if document is marked as visible to clients
      metadata_values['client_visible'] == 'true' || public_document?
    end
    
    def technical_document?
      document_type_classification == 'technical' ||
        title.downcase.match?(/technique|spec|cahier/)
    end
    
    def test_document?
      document_type_classification == 'test' ||
        title.downcase.match?(/test|essai|controle/)
    end
    
    def compliance_required?
      document_type_classification.in?(['legal', 'regulatory', 'permit']) ||
        metadata_values['compliance_required'] == 'true'
    end
    
    def compliance_validated?
      validation_requests.where(validation_type: 'compliance', status: 'validated').any?
    end
    
    def document_type_classification
      # This would be determined by AI classification or metadata
      metadata_values['document_type'] || 'general'
    end
    
    def public_document?
      # Check if document is marked as public
      false # Default to private
    end
    
    private
    
    def office_mime_types
      [
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document', # .docx
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', # .xlsx
        'application/vnd.openxmlformats-officedocument.presentationml.presentation', # .pptx
        'application/msword', # .doc
        'application/vnd.ms-excel', # .xls
        'application/vnd.ms-powerpoint' # .ppt
      ]
    end
  end
end