# Concern for virus scanning functionality
module Documents::VirusScannable
  extend ActiveSupport::Concern

  included do
    # Virtual attribute for quarantine status
    attr_accessor :quarantined
    
    # Virus scan status enum
    enum virus_scan_status: {
      scan_pending: 'pending',
      scan_clean: 'clean',
      scan_infected: 'infected',
      scan_error: 'error'
    }, _prefix: true
    
    scope :virus_clean, -> { where(virus_scan_status: 'clean') }
    scope :virus_infected, -> { where(virus_scan_status: 'infected') }
    scope :virus_scan_pending, -> { where(virus_scan_status: 'pending') }
    
    # Enqueue virus scan after file attachment
    after_create_commit :enqueue_virus_scan_job, if: :file_attached?
    after_update_commit :enqueue_virus_scan_job, if: :file_changed?
  end

  # Check if virus scan detected infection
  def virus_scan_infected?
    virus_scan_status == 'infected'
  end

  # Check if virus scan is clean
  def virus_scan_clean?
    virus_scan_status == 'clean'
  end

  # Check if virus scan is pending
  def virus_scan_pending?
    virus_scan_status == 'pending'
  end

  # Check if virus scan had an error
  def virus_scan_error?
    virus_scan_status == 'error'
  end

  # Mark virus scan as clean
  def mark_virus_clean!
    update!(
      virus_scan_status: 'clean',
      virus_scan_result: 'No threats detected'
    )
  end

  # Mark virus scan as infected
  def mark_virus_infected!(threat_details = nil)
    update!(
      virus_scan_status: 'infected',
      virus_scan_result: threat_details || 'Threat detected'
    )
    
    # Quarantine the file
    quarantine_infected_file!
  end

  # Mark virus scan as error
  def mark_virus_scan_error!(error_message)
    update!(
      virus_scan_status: 'error',
      virus_scan_result: error_message
    )
  end

  # Check if file is safe to download
  def safe_to_download?
    virus_scan_clean? || virus_scan_status.nil?
  end

  # Alias methods for enum-style interface
  def scan_clean!
    mark_virus_clean!
  end

  def scan_infected!(threat_details = nil)
    mark_virus_infected!(threat_details)
  end

  # Get virus scan summary
  def virus_scan_summary
    {
      status: virus_scan_status,
      result: virus_scan_result,
      safe: safe_to_download?
    }
  end

  private

  def file_changed?
    saved_change_to_attribute?(:file_blob_id)
  end

  def quarantine_infected_file!
    # Mark as archived to prevent access
    archive! if may_archive?
    
    # Notify administrators
    NotificationService.notify_virus_detected(self)
    
    Rails.logger.warn "Infected file quarantined: Document ##{id}"
  end

  def enqueue_virus_scan_job
    VirusScanJob.perform_later(self)
  end
end