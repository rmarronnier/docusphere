# Concern for AI classification and entity extraction
module Documents::AiProcessable
  extend ActiveSupport::Concern

  included do
    after_update_commit :enqueue_ai_processing_job, if: :should_process_with_ai?
    
    scope :ai_processed, -> { where.not(ai_processed_at: nil) }
    scope :ai_pending, -> { where(ai_processed_at: nil) }
    scope :by_ai_category, ->(category) { where(ai_category: category) }
    scope :high_confidence, -> { where('ai_confidence >= ?', 0.8) }
  end

  # Check if AI processed
  def ai_processed?
    ai_processed_at.present?
  end

  # Get AI classification category
  def ai_classification_category
    ai_category || 'unknown'
  end

  # Get AI confidence as percentage
  def ai_classification_confidence_percent
    return 0 unless ai_confidence
    (ai_confidence * 100).round(1)
  end

  # Get AI entities by type
  def ai_entities_by_type(entity_type = nil)
    return [] unless ai_entities.present?
    
    entities = ai_entities.is_a?(Array) ? ai_entities : []
    return entities unless entity_type
    
    entities.select { |entity| entity['type'] == entity_type.to_s }
  end

  # Extract specific entity types
  def ai_extracted_emails
    ai_entities_by_type('email').map { |e| e['value'] }
  end

  def ai_extracted_phones
    ai_entities_by_type('phone').map { |e| e['value'] }
  end

  def ai_extracted_amounts
    ai_entities_by_type('amount').map { |e| e['value'] }
  end

  def ai_extracted_dates
    ai_entities_by_type('date').map { |e| e['value'] }
  end

  def ai_extracted_addresses
    ai_entities_by_type('address').map { |e| e['value'] }
  end

  def ai_extracted_organizations
    ai_entities_by_type('organization').map { |e| e['value'] }
  end

  def ai_extracted_people
    ai_entities_by_type('person').map { |e| e['value'] }
  end

  # Check if should process with AI
  def should_process_with_ai?
    return false unless file.attached?
    return false if ai_processed?
    
    # AI processing after basic processing
    processing_status_changed? && 
    processing_status == 'completed' && 
    processing_status_was == 'processing'
  end

  # Check if file type supports AI processing
  def supports_ai_processing?
    return false unless file.attached?
    
    # File types supported by AI
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

  # Mark AI processing as started
  def start_ai_processing!
    update!(
      processing_status: 'ai_processing',
      ai_processing_started_at: Time.current
    )
  end

  # Mark AI processing as completed
  def complete_ai_processing!(category:, confidence:, entities: [])
    update!(
      ai_category: category,
      ai_confidence: confidence,
      ai_entities: entities,
      ai_processed_at: Time.current,
      processing_status: 'completed'
    )
  end

  # Get AI insights summary
  def ai_insights_summary
    return nil unless ai_processed?
    
    {
      category: ai_classification_category,
      confidence: ai_classification_confidence_percent,
      entities: {
        emails: ai_extracted_emails.count,
        phones: ai_extracted_phones.count,
        amounts: ai_extracted_amounts.count,
        dates: ai_extracted_dates.count,
        organizations: ai_extracted_organizations.count,
        people: ai_extracted_people.count
      },
      processed_at: ai_processed_at
    }
  end
  
  # Get AI summary - returns extracted text excerpt if no dedicated summary
  def ai_summary
    # Since we don't have a dedicated ai_summary field, we can return
    # a truncated version of the extracted text as a summary
    return nil unless ai_processed? && extracted_text.present?
    extracted_text.truncate(200, separator: ' ')
  end

  private

  def enqueue_ai_processing_job
    return unless supports_ai_processing?
    
    # Delay to allow basic processing to finalize
    DocumentAiProcessingJob.set(wait: 30.seconds).perform_later(id)
  end
end