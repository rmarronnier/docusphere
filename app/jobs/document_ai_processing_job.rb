class DocumentAiProcessingJob < ApplicationJob
  queue_as :ai_processing
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(document_id)
    document = Document.find_by(id: document_id)
    return unless document
    
    Rails.logger.info "Démarrage du traitement IA pour le document #{document.id}"
    
    # Vérification que le document n'a pas déjà été traité
    return if document.ai_processed_at.present?
    
    # Marquage du début de traitement
    document.update(processing_status: 'ai_processing')
    
    # Traitement par le service IA
    processing_service = DocumentProcessingService.new
    
    # Vérification de la santé du service
    unless processing_service.health_check
      Rails.logger.error "Service d'extraction non disponible pour le document #{document.id}"
      document.update(
        processing_status: 'failed',
        processing_error: 'Service d\'extraction non disponible'
      )
      return
    end
    
    # Try local AI classification first
    if AiClassificationService.classify_document(document)
      Rails.logger.info "Classification IA locale réussie pour le document #{document.id}"
      document.update(processing_status: 'completed')
    else
      # Fallback to external processing service
      processing_service.process_document(document)
    end
    
    # Notification de fin de traitement
    notify_processing_completion(document)
    
  rescue => e
    Rails.logger.error "Erreur dans DocumentAiProcessingJob pour le document #{document_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    if document
      document.update(
        processing_status: 'failed',
        processing_error: e.message
      )
    end
    
    raise e
  end
  
  private
  
  def notify_processing_completion(document)
    # Notification à l'utilisateur (optionnel)
    if document.processing_status == 'completed'
      Rails.logger.info "Traitement IA terminé avec succès pour le document #{document.id}"
      
      # Ici vous pourriez ajouter une notification à l'utilisateur
      # NotificationService.notify_user(document.user, :ai_processing_completed, document)
      
      # Ou envoyer un webhook
      # WebhookService.send_webhook(:document_ai_processed, document)
    end
  end
end