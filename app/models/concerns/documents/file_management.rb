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