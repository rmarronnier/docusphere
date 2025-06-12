# Concern for document versioning using PaperTrail
module Documents::Versionable
  extend ActiveSupport::Concern

  included do
    has_paper_trail versions: { class_name: 'DocumentVersion' },
                    on: [:update, :destroy],
                    ignore: [:processing_status, :processing_started_at, :processing_completed_at,
                             :virus_scan_status, :virus_scan_result, :locked_at, :ai_processed_at,
                             :ai_processing_started_at, :current_version_number],
                    meta: {
                      comment: :version_comment,
                      created_by_id: proc { Current.user&.id }
                    }
    
    attr_accessor :version_comment
  end

  # Create a new version
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
      
      # Force a trackable change to ensure version creation
      # We'll update the updated_at timestamp to trigger PaperTrail
      self.updated_at = Time.current
      
      # Save with PaperTrail tracking
      self.paper_trail_event = 'update'
      save!
      
      # Get the newly created version and set its version number
      new_version = versions.last
      if new_version
        new_version_number = versions.count
        new_version.update_columns(
          version_number: new_version_number,
          comment: comment,
          created_by_id: user.id
        )
        
        # Update document's current version number
        update_columns(
          current_version_number: new_version_number,
          processing_status: 'pending',
          ai_processed_at: nil,
          extracted_text: nil
        )
      end
      
      # Trigger reprocessing if not in test environment
      enqueue_processing_job unless Rails.env.test?
      
      # Return the newly created version
      new_version
    end
  rescue => e
    Rails.logger.error "Error creating version: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  # Restore a specific version
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

  # Get current version
  def current_version
    versions.for_documents.first
  end

  # Get previous versions
  def previous_versions
    versions.for_documents.offset(1)
  end

  # Count versions
  def version_count
    versions.for_documents.count
  end

  # Check if has versions
  def has_versions?
    version_count > 0
  end

  # Get latest version
  def latest_version
    versions.for_documents.first
  end

  # Get oldest version
  def oldest_version
    versions.for_documents.last
  end

  # Get version by number
  def version_at(version_number)
    versions.for_documents.find_by(version_number: version_number)
  end

  # Get versions in date range
  def versions_between(start_date, end_date)
    versions.for_documents.where(created_at: start_date..end_date)
  end

  # Get version history
  def version_history
    versions.for_documents.includes(:created_by).map do |version|
      {
        id: version.id,
        version_number: version.version_number,
        event: version.event,
        comment: version.comment,
        created_by: version.created_by_name,
        created_at: version.created_at,
        file_name: version.file_name,
        file_size: version.file_size_human
      }
    end
  end

  # Compare with another version
  def compare_with_version(version_id)
    version = versions.find(version_id)
    return nil unless version.is_a?(DocumentVersion)
    
    version.diff_with(current_version || self)
  end

  # Get current version number
  def current_version_number
    read_attribute(:current_version_number) || versions.count + 1
  end

  # Get previous version (reified object)
  def previous_version
    return nil unless versions.any?
    versions.first.reify
  end

  # Revert to a specific version by number
  def revert_to_version!(version_number)
    version = version_at(version_number)
    return false unless version
    
    restore_version!(version.id, Current.user || uploaded_by)
  end

  # Get document state at specific timestamp
  def version_at(timestamp)
    if timestamp.is_a?(Integer)
      # If integer, treat as version number
      versions.for_documents.find_by(version_number: timestamp)
    else
      # If timestamp, find version at that time
      versions.for_documents.where('created_at <= ?', timestamp).first
    end
  end

  # Get user who made last change
  def changed_by
    if versions.any?
      version = versions.first
      if version.respond_to?(:created_by) && version.created_by.present?
        version.created_by
      elsif version.whodunnit.present?
        User.find_by(id: version.whodunnit)
      else
        uploaded_by
      end
    else
      uploaded_by
    end
  end

  # Get summary of all versions
  def version_summary
    {
      total_versions: version_count,
      current_version: current_version_number,
      last_modified: updated_at,
      last_modified_by: changed_by&.display_name,
      versions: version_history
    }
  end

  # Check if document has changes since timestamp
  def has_changes_since?(timestamp)
    versions.where('created_at > ?', timestamp).exists?
  end

  # Check if last version was a major change
  def major_version?
    return false unless versions.any?
    
    last_version = versions.first
    last_version.comment&.include?('[MAJOR]') || 
      (last_version.respond_to?(:file_changes?) && last_version.file_changes?)
  end

  # Create a version specifically for file changes
  def create_file_version!(new_file, user, comment = nil)
    self.version_comment = comment || "Nouveau fichier uploadé"
    create_version!(new_file, user, comment)
  end

  # Get only versions that included file changes
  def file_versions
    versions.for_documents.select do |v|
      v.respond_to?(:file_changes?) && v.file_changes?
    end
  end

  # Diff current state with a specific version number
  def diff_with_version(version_number)
    version = version_at(version_number)
    return {} unless version
    
    version.diff_with(self)
  end

  # Get changes between two version numbers
  def changes_between_versions(v1_number, v2_number)
    v1 = version_at(v1_number)
    v2 = version_at(v2_number)
    
    return {} unless v1 && v2
    
    v1.diff_with(v2.reify || self)
  end

  private

  def enqueue_processing_job
    DocumentProcessingJob.perform_later(self)
  end
end