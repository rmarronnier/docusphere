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

  private

  def enqueue_processing_job
    DocumentProcessingJob.perform_later(self)
  end
end