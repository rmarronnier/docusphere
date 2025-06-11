# Concern for document processing pipeline
module Documents::Processable
  extend ActiveSupport::Concern

  SUPPORTED_FORMATS = {
    pdf: ['application/pdf'],
    word: ['application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    excel: ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
    powerpoint: ['application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'],
    image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'],
    audio: ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/webm'],
    video: ['video/mp4', 'video/webm', 'video/ogg'],
    mail: ['message/rfc822'],
    zip: ['application/zip', 'application/x-zip-compressed']
  }.freeze

  included do
    # Virtual attribute for content hash
    attr_accessor :content_hash
    
    # Processing status enum
    enum processing_status: {
      pending: 'pending',
      processing: 'processing',
      ai_processing: 'ai_processing',
      completed: 'completed',
      failed: 'failed'
    }
    
    # Thumbnail generation status (requis par tests ThumbnailGenerationJob)
    attr_accessor :thumbnail_generation_status
    
    # Callbacks
    after_create_commit :enqueue_processing_job
    
    scope :processing_pending, -> { where(processing_status: 'pending') }
    scope :processing_completed, -> { where(processing_status: 'completed') }
    scope :processing_failed, -> { where(processing_status: 'failed') }
  end

  # Check if format is supported
  def supported_format?
    SUPPORTED_FORMATS.values.flatten.include?(file.blob.content_type)
  end

  # Get document type based on content type
  def document_type
    SUPPORTED_FORMATS.each do |type, formats|
      return type.to_s if formats.include?(file.blob.content_type)
    end
    'other'
  end

  # Check if preview exists
  def preview_generated?
    preview.attached?
  end

  # Check if thumbnail exists
  def thumbnail_generated?
    thumbnail.attached?
  end

  # Is this an image file?
  def image?
    file.content_type.start_with?('image/') if file.attached?
  end

  # Is this a PDF?
  def pdf?
    file.content_type == 'application/pdf' if file.attached?
  end

  # Is this an office document?
  def office_document?
    return false unless file.attached?
    
    office_types = [
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/msword',
      'application/vnd.ms-excel',
      'application/vnd.ms-powerpoint'
    ]
    
    office_types.include?(file.content_type)
  end

  # Should perform OCR?
  def needs_ocr?
    image? || (pdf? && !has_text?)
  end

  # Check if document has extractable text
  def has_text?
    content.present? && content.strip.length > 50
  end

  # Get extracted content
  def extracted_content
    content.presence || ''
  end

  # Mark processing as started
  def start_processing!
    update!(
      processing_status: 'processing',
      processing_started_at: Time.current
    )
  end

  # Mark processing as completed
  def complete_processing!
    update!(
      processing_status: 'completed',
      processing_completed_at: Time.current,
      processing_error: nil
    )
  end

  # Mark processing as failed
  def fail_processing!(error_message)
    update!(
      processing_status: 'failed',
      processing_completed_at: Time.current,
      processing_error: error_message
    )
  end

  # Store extracted metadata
  def add_metadata(key, value, field = nil)
    metadata.create!(
      key: key,
      value: value.to_s,
      metadata_field: field
    )
  end

  # Store document properties as metadata
  def store_document_properties(properties)
    properties.each do |key, value|
      next if value.blank?
      add_metadata("document_#{key}", value)
    end
  end

  # Get processing summary
  def processing_summary
    {
      status: processing_status,
      started_at: processing_started_at,
      completed_at: processing_completed_at,
      error: processing_error,
      duration: processing_duration,
      metadata_count: metadata.count,
      has_preview: preview_generated?,
      has_thumbnail: thumbnail_generated?,
      has_text: has_text?
    }
  end

  # Calculate processing duration
  def processing_duration
    return nil unless processing_started_at && processing_completed_at
    
    (processing_completed_at - processing_started_at).round(2)
  end

  # Check if ready for download
  def ready_for_download?
    processing_completed? && safe_to_download?
  end
  
  # Helper methods for status checks (required by tests)
  def processed?
    processing_status == 'completed'
  end
  
  def processing?
    processing_status == 'processing'
  end
  
  def failed?
    processing_status == 'failed'
  end

  private

  def enqueue_processing_job
    # Only enqueue if file is attached
    return unless file.attached?
    DocumentProcessingJob.perform_later(self)
  end
end