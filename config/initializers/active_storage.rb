# frozen_string_literal: true

# Configure Active Storage variants
module ActiveStorageVariants
  # Standard thumbnail sizes
  THUMBNAIL_VARIANTS = {
    thumb: { resize_to_limit: [200, 200], format: :jpg, quality: 85 },
    medium: { resize_to_limit: [800, 600], format: :jpg, quality: 90 },
    large: { resize_to_limit: [1200, 900], format: :jpg, quality: 95 }
  }.freeze
  
  # Special variants for different use cases
  SPECIAL_VARIANTS = {
    # For document grids
    grid_thumb: { resize_to_fill: [300, 400], format: :jpg, quality: 85 },
    
    # For previews
    preview_full: { resize_to_limit: [1600, 1200], format: :jpg, quality: 95 },
    
    # For mobile
    mobile_thumb: { resize_to_limit: [150, 150], format: :jpg, quality: 80 },
    mobile_preview: { resize_to_limit: [600, 800], format: :jpg, quality: 85 }
  }.freeze
end

# Monkey patch to add helper methods to Document model
module ActiveStorageDocumentHelpers
  extend ActiveSupport::Concern
  
  included do
    # Generate a thumbnail URL with specified variant
    def thumbnail_url(variant = :thumb)
      return ActionController::Base.helpers.asset_path('document-placeholder.png') unless file.attached?
      
      if thumbnail.attached?
        Rails.application.routes.url_helpers.rails_blob_path(thumbnail, only_path: true)
      elsif preview.attached? && preview.variable?
        Rails.application.routes.url_helpers.rails_representation_path(
          preview.variant(ActiveStorageVariants::THUMBNAIL_VARIANTS[variant]),
          only_path: true
        )
      elsif file.attached? && file.variable?
        Rails.application.routes.url_helpers.rails_representation_path(
          file.variant(ActiveStorage::VariantDefinition::THUMBNAIL_VARIANTS[variant]),
          only_path: true
        )
      else
        icon_for_content_type
      end
    rescue StandardError => e
      Rails.logger.error "Thumbnail generation error: #{e.message}"
      icon_for_content_type
    end
    
    # Get icon path based on content type
    def icon_for_content_type
      icon_file = case file_content_type
      when /pdf/
        'file-icons/pdf-icon.svg'
      when /word|document/
        'file-icons/word-icon.svg'
      when /excel|spreadsheet/
        'file-icons/excel-icon.svg'
      when /powerpoint|presentation/
        'file-icons/ppt-icon.svg'
      when /zip|compressed/
        'file-icons/zip-icon.svg'
      when /text/
        'file-icons/txt-icon.svg'
      else
        'file-icons/generic-icon.svg'
      end
      
      ActionController::Base.helpers.asset_path(icon_file)
    end
    
    # Preview URL with variant
    def preview_url(variant = :medium)
      return nil unless file.attached?
      
      if preview.attached? && preview.variable?
        Rails.application.routes.url_helpers.rails_representation_path(
          preview.variant(ActiveStorageVariants::THUMBNAIL_VARIANTS[variant]),
          only_path: true
        )
      elsif file.previewable?
        Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Preview generation error: #{e.message}"
      nil
    end
    
    private
    
    def helpers
      Rails.application.routes.url_helpers
    end
  end
end

# Include the helpers in Document model when it's loaded
Rails.application.config.to_prepare do
  if defined?(Document)
    Document.include(ActiveStorageDocumentHelpers)
  end
end