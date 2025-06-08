# Concern for adding file upload capabilities to models
module Uploadable
  extend ActiveSupport::Concern

  included do
    # Callbacks
    after_create_commit :enqueue_processing_job, if: :has_file_attached?
    after_update_commit :enqueue_reprocessing_job, if: :should_reprocess?
    
    # Scopes
    scope :with_files, -> { joins(:file_attachment) }
    scope :without_files, -> { left_joins(:file_attachment).where(active_storage_attachments: { id: nil }) }
    scope :by_content_type, ->(type) { joins(:file_blob).where(active_storage_blobs: { content_type: type }) }
    scope :by_file_size, ->(min: nil, max: nil) {
      scope = joins(:file_blob)
      scope = scope.where('active_storage_blobs.byte_size >= ?', min) if min
      scope = scope.where('active_storage_blobs.byte_size <= ?', max) if max
      scope
    }
  end

  class_methods do
    # Define which file types are supported
    def supports_file_types(*types)
      @supported_file_types = types.map(&:to_s)
    end

    def supported_file_types
      @supported_file_types || []
    end

    # Define max file size
    def max_file_size(size)
      @max_file_size = size
    end

    def maximum_file_size
      @max_file_size || 100.megabytes
    end
  end

  # Check if file is attached
  def has_file_attached?
    respond_to?(:file) && file.attached?
  end

  # Get file metadata
  def file_metadata
    return {} unless has_file_attached?
    
    {
      filename: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size,
      checksum: file.checksum,
      created_at: file.created_at
    }
  end

  # Human readable file size
  def file_size_human
    return nil unless has_file_attached?
    
    ActiveSupport::NumberHelper.number_to_human_size(file.byte_size)
  end

  # File extension
  def file_extension
    return nil unless has_file_attached?
    
    File.extname(file.filename.to_s).delete('.').downcase
  end

  # Check if file type is supported
  def supported_file_type?
    return true if self.class.supported_file_types.empty?
    return false unless has_file_attached?
    
    self.class.supported_file_types.include?(file.content_type)
  end

  # Check if file size is within limits
  def file_size_valid?
    return true unless has_file_attached?
    
    file.byte_size <= self.class.maximum_file_size
  end

  # Generate preview
  def generate_preview!
    return false unless has_file_attached?
    return false unless respond_to?(:preview)
    
    if file.previewable?
      preview.attach(
        io: StringIO.new(file.preview(resize_to_limit: [1024, 1024]).processed),
        filename: "preview_#{file.filename}",
        content_type: 'image/png'
      )
    end
  end

  # Generate thumbnail
  def generate_thumbnail!
    return false unless has_file_attached?
    return false unless respond_to?(:thumbnail)
    
    if file.variable?
      thumbnail.attach(
        io: StringIO.new(file.variant(resize_to_limit: [300, 300]).processed),
        filename: "thumb_#{file.filename}",
        content_type: 'image/png'
      )
    elsif file.previewable?
      thumbnail.attach(
        io: StringIO.new(file.preview(resize_to_limit: [300, 300]).processed),
        filename: "thumb_#{file.filename}",
        content_type: 'image/png'
      )
    end
  end

  # Replace file
  def replace_file!(new_file)
    transaction do
      # Store old file info if needed
      old_file_info = file_metadata if has_file_attached?
      
      # Purge old file
      file.purge if has_file_attached?
      
      # Attach new file
      file.attach(new_file)
      
      # Track the change
      if respond_to?(:file_replacements)
        file_replacements.create!(
          old_file: old_file_info,
          new_file: file_metadata,
          replaced_by: Current.user,
          replaced_at: Time.current
        )
      end
    end
  end

  # Download URL with expiration
  def download_url(expires_in: 5.minutes)
    return nil unless has_file_attached?
    
    Rails.application.routes.url_helpers.rails_blob_url(file, expires_in: expires_in)
  end

  # Direct upload URL for frontend uploads
  def direct_upload_url
    return nil unless has_file_attached?
    
    Rails.application.routes.url_helpers.rails_direct_uploads_url
  end

  # Should reprocess file?
  def should_reprocess?
    return false unless has_file_attached?
    
    saved_change_to_attribute?(:processing_status) && 
    processing_status == 'pending_reprocess'
  end

  # Mark for reprocessing
  def mark_for_reprocessing!
    update!(processing_status: 'pending_reprocess') if respond_to?(:processing_status)
  end

  # File virus scan
  def scan_for_virus!
    return false unless has_file_attached?
    return false unless respond_to?(:virus_scan_status)
    
    update!(virus_scan_status: 'scanning')
    VirusScanJob.perform_later(self)
  end

  # Extract text content
  def extract_content!
    return false unless has_file_attached?
    return false unless respond_to?(:content)
    
    ExtractContentJob.perform_later(self)
  end

  private

  def enqueue_processing_job
    FileProcessingJob.perform_later(self) if respond_to?(:processing_status)
  end

  def enqueue_reprocessing_job
    FileReprocessingJob.perform_later(self)
  end
end