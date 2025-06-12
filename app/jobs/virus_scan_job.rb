class VirusScanJob < ApplicationJob
  queue_as :document_processing
  
  retry_on StandardError, wait: 5.seconds, attempts: 3
  
  def perform(document_id)
    document = Document.find(document_id)
    return unless document.file.attached?
    return if document.virus_scan_status.present?
    
    # Mark as scanning
    document.update!(virus_scan_status: 'pending')
    
    begin
      # Initialize ClamAV client with config
      config = Rails.application.config.clamav || {}
      client = ClamAV::Client.new(
        host: config[:host] || 'localhost',
        port: config[:port] || 3310,
        timeout: config[:timeout] || 30
      )
      
      # Scan the file
      document.file.open do |file|
        # ClamAV::Client returns a response object
        response = client.execute(ClamAV::Commands::InstreamCommand.new(File.read(file.path)))
        
        if response && response.match(/FOUND/)
          virus_name = response.split(':').last.strip.gsub(' FOUND', '')
          handle_infected_file(document, virus_name)
        else
          mark_as_clean(document)
        end
      end
      
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Timeout::Error => e
      # ClamAV is not available
      Rails.logger.error "ClamAV connection failed: #{e.message}"
      document.update!(
        virus_scan_status: 'error',
        virus_scan_result: "ClamAV unavailable: #{e.message}",
        virus_scan_performed_at: Time.current
      )
      # Don't block processing if antivirus is unavailable
      
    rescue StandardError => e
      Rails.logger.error "Virus scan failed for document #{document.id}: #{e.message}"
      document.update!(
        virus_scan_status: 'error',
        virus_scan_result: e.message,
        virus_scan_performed_at: Time.current
      )
    end
  end
  
  private
  
  def handle_infected_file(document, virus_name)
    document.update!(
      virus_scan_status: 'infected',
      virus_scan_result: "Infected: #{virus_name}",
      virus_scan_performed_at: Time.current,
      status: 'locked',
      processing_status: 'failed',
      processing_error: "Virus detected: #{virus_name}"
    )
    
    # Add metadata
    document.add_metadata('virus_detected', virus_name)
    document.add_metadata('quarantined_at', Time.current.iso8601)
    
    # Create notification for admins
    notify_admins_of_infection(document, virus_name)
    
    # Log security event
    Rails.logger.error "SECURITY: Virus detected in document #{document.id}: #{virus_name}"
  end
  
  def mark_as_clean(document)
    document.update!(
      virus_scan_status: 'clean',
      virus_scan_result: 'No threats detected',
      virus_scan_performed_at: Time.current
    )
    
    document.add_metadata('virus_scan_engine', 'ClamAV')
    document.add_metadata('virus_scan_date', Date.current.to_s)
  end
  
  def notify_admins_of_infection(document, virus_name)
    # Find all admin users
    admin_users = User.where(role: 'admin')
    
    admin_users.each do |admin|
      Notification.create!(
        user: admin,
        notification_type: 'security_alert',
        title: 'Virus détecté',
        message: "Un virus (#{virus_name}) a été détecté dans le document '#{document.title}' uploadé par #{document.user.full_name}",
        data: {
          document_id: document.id,
          virus_name: virus_name,
          user_id: document.user_id
        }
      )
    end
  end
end