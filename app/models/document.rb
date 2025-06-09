class Document < ApplicationRecord
  include AASM
  include Authorizable
  include Linkable
  include Validatable
  
  has_paper_trail
  
  belongs_to :uploaded_by, class_name: 'User', foreign_key: 'uploaded_by_id'
  belongs_to :locked_by, class_name: 'User', foreign_key: 'locked_by_id', optional: true
  belongs_to :parent, class_name: 'Document', optional: true
  belongs_to :space
  belongs_to :folder, optional: true
  belongs_to :documentable, polymorphic: true, optional: true
  
  has_many :children, class_name: 'Document', foreign_key: 'parent_id', dependent: :destroy
  has_many :shares, as: :shareable, dependent: :destroy
  has_many :document_shares, dependent: :destroy
  has_many :metadata, class_name: 'Metadatum', as: :metadatable, dependent: :destroy
  has_many :document_tags, dependent: :destroy
  has_many :tags, through: :document_tags
  has_many :source_links, class_name: 'Link', as: :source, dependent: :destroy
  has_many :target_links, class_name: 'Link', as: :target, dependent: :destroy
  # Use PaperTrail versions instead of custom document_versions
  # Access versions through: document.versions (returns DocumentVersion instances)
  
  has_one_attached :file
  has_one_attached :preview
  has_one_attached :thumbnail
  
  validates :title, presence: true
  validates :file, presence: true
  validates :file_size, numericality: { less_than_or_equal_to: 100.megabytes }, if: :file_attached?
  
  # Processing status enum
  enum processing_status: {
    pending: 'pending',
    processing: 'processing',
    ai_processing: 'ai_processing',
    completed: 'completed',
    failed: 'failed'
  }
  
  # Virus scan status enum
  enum virus_scan_status: {
    scan_pending: 'pending',
    scan_clean: 'clean',
    scan_infected: 'infected',
    scan_error: 'error'
  }, _prefix: true
  
  # Callbacks
  after_create_commit :enqueue_processing_job
  after_update_commit :enqueue_ai_processing_job, if: :should_process_with_ai?
  
  searchkick word_start: [:title, :description], 
             searchable: [:title, :description, :content, :metadata_text],
             filterable: [:document_type, :document_category, :documentable_type, :created_at, :user_id, :space_id, :tags]
  
  audited
  has_paper_trail versions: { class_name: 'DocumentVersion' },
                  on: [:update, :destroy],
                  ignore: [:processing_status, :processing_started_at, :processing_completed_at,
                           :virus_scan_status, :virus_scan_result, :locked_at, :ai_processed_at,
                           :ai_processing_started_at, :current_version_number],
                  meta: {
                    comment: :version_comment,
                    created_by_id: proc { Current.user&.id }
                  }
  
  aasm column: 'status' do
    state :draft, initial: true
    state :published
    state :locked
    state :archived
    state :marked_for_deletion
    state :deleted
    
    event :publish do
      transitions from: :draft, to: :published
    end
    
    event :lock do
      transitions from: [:draft, :published], to: :locked
      before do
        self.locked_at = Time.current
      end
    end
    
    event :unlock do
      transitions from: :locked, to: :published
      before do
        self.locked_by = nil
        self.locked_at = nil
        self.lock_reason = nil
        self.unlock_scheduled_at = nil
      end
    end
    
    event :archive do
      transitions from: [:published, :locked], to: :archived
    end
    
    event :mark_for_deletion do
      transitions from: [:published, :locked, :archived], to: :marked_for_deletion
    end
    
    event :soft_delete do
      transitions from: :marked_for_deletion, to: :deleted
    end
  end
  
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
  
  def supported_format?
    SUPPORTED_FORMATS.values.flatten.include?(file.blob.content_type)
  end
  
  def document_type
    SUPPORTED_FORMATS.each do |type, formats|
      return type.to_s if formats.include?(file.blob.content_type)
    end
    'other'
  end
  
  def search_data
    {
      title: title,
      description: description,
      content: extracted_content,
      metadata_text: metadata_text,
      document_type: document_type,
      document_category: document_category,
      documentable_type: documentable_type,
      created_at: created_at,
      user_id: uploaded_by_id,
      space_id: space_id,
      tags: tags.pluck(:name)
    }
  end
  
  def extracted_content
    # Return content if already extracted
    content.presence || ''
  end
  
  def metadata_text
    metadata.map { |m| "#{m.name}: #{m.value}" }.join(' ')
  end
  
  # Check if preview exists
  def preview_generated?
    preview.attached?
  end
  
  # Check if thumbnail exists
  def thumbnail_generated?
    thumbnail.attached?
  end
  
  # File size validation helper
  def file_attached?
    file.attached?
  end
  
  # Get file size in bytes
  def file_size
    file.blob.byte_size if file.attached?
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
  
  # Check if virus scan detected infection
  def virus_scan_infected?
    virus_scan_status == 'infected'
  end
  
  # AI-related methods
  def ai_processed?
    ai_processed_at.present?
  end
  
  def ai_classification_category
    ai_category || 'unknown'
  end
  
  def ai_classification_confidence_percent
    return 0 unless ai_confidence
    (ai_confidence * 100).round(1)
  end
  
  def ai_entities_by_type(entity_type = nil)
    return [] unless ai_entities.present?
    
    entities = ai_entities.is_a?(Array) ? ai_entities : []
    return entities unless entity_type
    
    entities.select { |entity| entity['type'] == entity_type.to_s }
  end
  
  def ai_extracted_emails
    ai_entities_by_type('email').map { |e| e['value'] }
  end
  
  def ai_extracted_phones
    ai_entities_by_type('phone').map { |e| e['value'] }
  end
  
  def ai_extracted_amounts
    ai_entities_by_type('amount').map { |e| e['value'] }
  end
  
  def should_process_with_ai?
    return false unless file.attached?
    return false if ai_processed?
    
    # Traitement IA après le traitement de base
    processing_status_changed? && 
    processing_status == 'completed' && 
    processing_status_was == 'processing'
  end
  
  def supports_ai_processing?
    return false unless file.attached?
    
    # Types de fichiers supportés par l'IA
    ai_supported_types = %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      text/plain
      image/jpeg
      image/png
      image/tiff
    ]
    
    ai_supported_types.include?(file.content_type)
  end
  
  # Document-specific validation methods
  def can_validate?(user)
    # Owner can always request validation
    return true if self.uploaded_by == user
    
    # Check if user has validation permission on the document
    return true if has_permission?(user, 'validation')
    
    # Check if user has validation permission on the space
    space.has_permission?(user, 'validation')
  end
  
  def has_permission?(user, permission_level)
    # Check if user has direct authorization
    authorizations.where(user: user, permission_level: permission_level).exists? ||
    # Check if user belongs to a group with authorization
    authorizations.joins(user_group: :users).where(user_group: { users: { id: user.id } }, permission_level: permission_level).exists?
  end
  
  def can_request_validation?(user)
    return false unless user
    return false if validation_pending?
    
    # Owner can always request validation
    return true if self.uploaded_by == user
    
    # Admin can request validation
    return true if admin_by?(user)
    
    # Users with write permission can request validation
    writable_by?(user)
  end
  
  def validation_summary
    return nil unless current_validation_request
    
    {
      status: validation_status,
      progress: current_validation_request.validation_progress,
      requester: current_validation_request.requester.full_name,
      created_at: current_validation_request.created_at,
      completed_at: current_validation_request.completed_at
    }
  end
  
  # Locking methods
  def lock_document!(user, reason: nil, scheduled_unlock: nil)
    return false unless can_lock?(user)
    
    self.locked_by = user
    self.lock_reason = reason
    self.unlock_scheduled_at = scheduled_unlock
    
    lock!
  end
  
  def unlock_document!(user)
    return false unless can_unlock?(user)
    
    unlock!
  end
  
  def can_lock?(user)
    return false unless user
    return false if locked?
    
    # Owner can lock
    return true if uploaded_by == user
    
    # Admin can lock
    return true if admin_by?(user)
    
    # Users with write permission can lock
    writable_by?(user)
  end
  
  def can_unlock?(user)
    return false unless user
    return false unless locked?
    
    # The user who locked can unlock
    return true if locked_by == user
    
    # Owner can unlock
    return true if uploaded_by == user
    
    # Admin can unlock
    admin_by?(user)
  end
  
  def locked_by_user?(user)
    locked? && locked_by == user
  end
  
  def lock_expired?
    return false unless locked?
    return false unless unlock_scheduled_at
    
    unlock_scheduled_at <= Time.current
  end
  
  def editable_by?(user)
    return false if locked? && !locked_by_user?(user)
    
    writable_by?(user)
  end
  
  # Versioning methods using PaperTrail
  attr_accessor :version_comment
  
  def create_version!(uploaded_file, user, comment = nil)
    return false unless uploaded_file.present?
    
    transaction do
      # Set version metadata
      self.version_comment = comment
      PaperTrail.request.whodunnit = user.id.to_s
      
      # Store old file info before update
      old_file_name = file.filename.to_s if file.attached?
      
      # Update main document file
      self.file.purge if self.file.attached?
      self.file.attach(uploaded_file)
      
      # Save with PaperTrail tracking
      self.paper_trail_event = 'update'
      save!
      
      # Reset processing status for new version
      update_columns(
        processing_status: 'pending',
        ai_processed_at: nil,
        extracted_text: nil
      )
      
      # Trigger reprocessing
      enqueue_processing_job
      
      # Return the newly created version
      versions.last
    end
  end
  
  def restore_version!(version_id, user)
    version = versions.find(version_id)
    return false unless version.is_a?(DocumentVersion)
    
    transaction do
      # Use DocumentVersion's restore method
      restored = version.restore!(user)
      
      if restored
        # Reset processing for restored version
        update_columns(
          processing_status: 'pending',
          ai_processed_at: nil,
          extracted_text: nil
        )
        
        enqueue_processing_job
      end
      
      restored
    end
  end
  
  def current_version
    versions.for_documents.first
  end
  
  def previous_versions
    versions.for_documents.offset(1)
  end
  
  def version_count
    versions.for_documents.count
  end
  
  def has_versions?
    version_count > 0
  end
  
  def latest_version
    versions.for_documents.first
  end
  
  def oldest_version
    versions.for_documents.last
  end
  
  def version_at(version_number)
    versions.for_documents.find_by(version_number: version_number)
  end
  
  def versions_between(start_date, end_date)
    versions.for_documents.where(created_at: start_date..end_date)
  end

  private
  
  def enqueue_processing_job
    DocumentProcessingJob.perform_later(self)
  end
  
  def enqueue_ai_processing_job
    return unless supports_ai_processing?
    
    # Délai pour permettre la finalisation du traitement de base
    DocumentAiProcessingJob.set(wait: 30.seconds).perform_later(id)
  end
end