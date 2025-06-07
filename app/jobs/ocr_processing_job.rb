class OcrProcessingJob < ApplicationJob
  queue_as :ocr_processing
  
  def perform(document)
    return unless document.file.attached?
    return if document.ocr_performed?
    
    # Extract text using OCR
    text = perform_ocr(document)
    
    if text.present?
      # Update document content
      existing_content = document.content || ''
      document.update!(
        content: existing_content.present? ? "#{existing_content}\n\n#{text}" : text,
        ocr_performed: true
      )
      
      # Add metadata
      document.add_metadata('ocr_performed_at', Time.current.iso8601)
      document.add_metadata('ocr_engine', 'tesseract')
      
      # Detect language
      language = detect_language(text)
      document.add_metadata('language', language) if language.present?
      
      # Complete processing if this was the last step
      document.complete_processing! if document.processing?
      
      # Trigger metadata extraction and auto-tagging after OCR
      MetadataExtractionJob.perform_later(document)
      AutoTaggingJob.perform_later(document)
    end
  end
  
  private
  
  def perform_ocr(document)
    document.file.open do |file|
      # Create RTesseract instance
      image = RTesseract.new(file.path)
      
      # Configure OCR options
      image.lang = detect_document_language(file.path)
      
      # Perform OCR
      text = image.to_s
      
      # Clean up the text
      clean_ocr_text(text)
    end
  rescue StandardError => e
    Rails.logger.error "OCR failed for document #{document.id}: #{e.message}"
    document.add_metadata('ocr_error', e.message)
    nil
  end
  
  def detect_document_language(file_path)
    # Try to detect language from a sample
    # For now, default to French with English fallback
    'fra+eng'
  end
  
  def detect_language(text)
    # Simple language detection based on common words
    french_words = %w[le la les un une des de du dans pour avec sur par est sont]
    english_words = %w[the a an in on at for with by is are was were]
    
    text_lower = text.downcase
    french_score = french_words.count { |word| text_lower.include?(" #{word} ") }
    english_score = english_words.count { |word| text_lower.include?(" #{word} ") }
    
    if french_score > english_score
      'fr'
    elsif english_score > 0
      'en'
    else
      nil
    end
  end
  
  def clean_ocr_text(text)
    return nil if text.blank?
    
    # Remove excessive whitespace
    text = text.gsub(/\s+/, ' ')
    
    # Remove page numbers and headers/footers patterns
    text = text.gsub(/^\d+\s*$/, '')
    text = text.gsub(/^page\s+\d+/i, '')
    
    # Remove non-printable characters
    text = text.gsub(/[^\u0020-\u007E\u00A0-\u00FF]/, '')
    
    # Trim
    text.strip
  end
end