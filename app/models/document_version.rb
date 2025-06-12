class DocumentVersion < PaperTrail::Version
  self.table_name = :versions
  
  # Relations
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :document, -> { where(versions: { item_type: 'Document' }) }, 
             foreign_key: :item_id, class_name: 'Document', optional: true
  
  # Attachments - store file data in file_metadata JSON column
  # This allows us to keep file versions without duplicating ActiveStorage attachments
  
  # Scopes
  scope :for_documents, -> { where(item_type: 'Document') }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_version_number, -> { order(version_number: :desc) }
  
  # Validations
  validates :item_type, inclusion: { in: ['Document'] }, if: -> { item_type == 'Document' }
  
  # Callbacks
  before_create :capture_file_metadata, if: :document_version?
  before_create :set_version_number, if: :document_version?
  after_create :send_version_notification, if: :document_version?
  
  # Helper methods
  def document_version?
    item_type == 'Document'
  end
  
  def file_name
    file_metadata['file_name']
  end
  
  def file_size
    file_metadata['file_size']
  end
  
  def content_type
    file_metadata['content_type']
  end
  
  def file_size_human
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
  
  # Get the document instance at this version
  def reified_document
    @reified_document ||= reify
  end
  
  # Check if this version can be restored
  def restorable?
    return false unless document_version?
    
    doc = Document.find_by(id: item_id)
    doc.present? && !doc.locked?
  end
  
  # Restore this version as the current document
  def restore!(user)
    return false unless restorable?
    
    doc = Document.find(item_id)
    
    transaction do
      # Create a new version entry for the restoration
      new_version = self.class.create!(
        item_type: 'Document',
        item_id: item_id,
        event: 'restore',
        whodunnit: user.id.to_s,
        created_by: user,
        comment: "Restored from version #{version_number}",
        object: object,
        object_changes: object_changes,
        file_metadata: file_metadata
      )
      
      # Mark that restoration happened
      # In a real implementation, we would restore the document state here
      # For now, we just track that a restoration was performed
      
      new_version
    end
  end
  
  # Compare with another version
  def diff_with(other_version)
    return {} unless other_version.is_a?(DocumentVersion)
    
    current_attrs = reified_document&.attributes || {}
    other_attrs = other_version.reified_document&.attributes || {}
    
    diff = {}
    (current_attrs.keys | other_attrs.keys).each do |key|
      next if %w[id created_at updated_at].include?(key)
      
      if current_attrs[key] != other_attrs[key]
        diff[key] = {
          from: other_attrs[key],
          to: current_attrs[key]
        }
      end
    end
    
    diff
  end
  
  # Display helpers
  def created_by_name
    created_by&.display_name || whodunnit || 'System'
  end
  
  def event_description
    case event
    when 'create'
      'Document créé'
    when 'update'
      'Document modifié'
    when 'destroy'
      'Document supprimé'
    when 'restore'
      'Document restauré'
    else
      event.humanize
    end
  end
  
  # Check if this version contains file changes
  def file_changes?
    return false unless file_metadata.present?
    
    # Check if object_changes contains file-related changes
    if object_changes.present?
      changes = object_changes.is_a?(String) ? JSON.parse(object_changes) : object_changes
      changes.key?('file_blob_id') || changes.key?('file') || changes.key?('file_metadata')
    else
      # If no object_changes, check if file_metadata is different from previous version
      prev_version = self.class.where(item_type: item_type, item_id: item_id)
                                .where('created_at < ?', created_at)
                                .order(created_at: :desc)
                                .first
      
      prev_version.nil? || prev_version.file_metadata != file_metadata
    end
  rescue JSON::ParserError
    false
  end
  
  # Get parsed object_changes as a hash
  def object_changes_hash
    return {} unless object_changes.present?
    
    if object_changes.is_a?(String)
      JSON.parse(object_changes)
    else
      object_changes
    end
  rescue JSON::ParserError
    {}
  end
  
  def icon_name
    case event
    when 'create'
      'plus-circle'
    when 'update'
      'edit'
    when 'destroy'
      'trash'
    when 'restore'
      'refresh'
    else
      'clock'
    end
  end
  
  private
  
  def capture_file_metadata
    return unless document_version? && item_id.present?
    
    # Get the document being versioned
    doc = Document.find_by(id: item_id)
    return unless doc&.file&.attached?
    
    self.file_metadata = {
      'file_name' => doc.file.filename.to_s,
      'file_size' => doc.file.byte_size,
      'content_type' => doc.file.content_type,
      'checksum' => doc.file.checksum,
      'created_at' => Time.current.iso8601
    }
  end
  
  def send_version_notification
    return unless document_version? && created_by_id.present? && item_id.present?
    
    # Get the document
    doc = Document.find_by(id: item_id)
    return unless doc
    
    # Notify document owner about new version
    if doc.uploaded_by_id != created_by_id
      Notification.notify_user(
        doc.uploaded_by,
        :document_version_created,
        "Nouvelle version de '#{doc.title}'",
        "#{created_by_name} a créé une nouvelle version du document",
        notifiable: doc
      )
    end
  end
  
  def restore_file_if_needed
    # This would require implementing file restoration logic
    # For now, we just track metadata
    # In a full implementation, you might store file blobs separately
    # or use a different strategy for file versioning
  end
  
  def set_version_number
    return unless document_version?
    
    # Get the highest version number for this document
    max_version = self.class.where(item_type: 'Document', item_id: item_id)
                            .maximum(:version_number) || 0
    
    self.version_number = max_version + 1
  end
end