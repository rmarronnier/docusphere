class DocumentProcessingJob < ApplicationJob
  queue_as :document_processing
  
  def perform(document)
    return if document.processing? || document.completed?
    
    document.start_processing!
    
    begin
      # 1. Virus scan first
      VirusScanJob.perform_now(document)
      return if document.virus_scan_infected?
      
      # 2. Extract content from document
      ContentExtractionJob.perform_now(document)
      
      # 3. Generate previews and thumbnails
      PreviewGenerationJob.perform_later(document)
      ThumbnailGenerationJob.perform_later(document)
      
      # 4. Extract metadata
      MetadataExtractionJob.perform_later(document)
      
      # 5. Auto-tag the document
      AutoTaggingJob.perform_later(document)
      
      # 6. If OCR is needed, queue it
      if document.needs_ocr?
        OcrProcessingJob.perform_later(document)
      end
      
      # Mark as completed if no async jobs remain
      unless document.needs_ocr?
        document.complete_processing!
      end
      
      # Update search index
      document.reindex
      
    rescue StandardError => e
      document.fail_processing!(e.message)
      Rails.logger.error "Document processing failed for document #{document.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise # Re-raise to trigger retry
    end
  end
end