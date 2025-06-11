# frozen_string_literal: true

module Documents
  module FileManagement
    extend ActiveSupport::Concern

    included do
      has_one_attached :file
      has_one_attached :preview
      has_one_attached :thumbnail
      
      validates :file, presence: true
      validates :file_size, numericality: { less_than_or_equal_to: 100.megabytes }, if: :file_attached?
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
  end
end