class DocumentProcessingService
  include HTTParty
  
  base_uri Rails.application.config.document_processor_url || 'http://document-processor:8000'
  
  def initialize
    @timeout = 30
    @retries = 3
  end
  
  def process_document(document)
    return unless document.file.attached?
    
    Rails.logger.info "Début du traitement IA pour le document #{document.id}"
    
    begin
      # Téléchargement temporaire du fichier
      temp_file = download_temp_file(document)
      
      # Appel au service d'extraction
      result = call_processor_api(temp_file, document)
      
      if result&.dig('status') == 'success'
        # Mise à jour du document avec les résultats IA
        update_document_with_ai_results(document, result)
        Rails.logger.info "Traitement IA réussi pour le document #{document.id}"
      else
        Rails.logger.error "Échec du traitement IA pour le document #{document.id}: #{result}"
        document.update(processing_status: 'failed', processing_error: result&.dig('detail') || 'Unknown error')
      end
      
    rescue => e
      Rails.logger.error "Erreur lors du traitement IA du document #{document.id}: #{e.message}"
      document.update(processing_status: 'failed', processing_error: e.message)
    ensure
      # Nettoyage du fichier temporaire
      temp_file&.close
      temp_file&.unlink if temp_file&.path && File.exist?(temp_file.path)
    end
  end
  
  def classify_text(text, language: 'fr')
    begin
      response = self.class.post('/classify-text', {
        body: {
          text: text,
          language: language
        }.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: @timeout
      })
      
      if response.success?
        response.parsed_response
      else
        Rails.logger.error "Erreur classification de texte: #{response.code} - #{response.body}"
        nil
      end
    rescue => e
      Rails.logger.error "Erreur lors de la classification de texte: #{e.message}"
      nil
    end
  end
  
  def health_check
    begin
      response = self.class.get('/health', timeout: 5)
      response.success? && response.dig('status') == 'healthy'
    rescue
      false
    end
  end
  
  def supported_formats
    begin
      response = self.class.get('/supported-formats', timeout: 10)
      response.success? ? response.parsed_response : nil
    rescue => e
      Rails.logger.error "Erreur récupération formats supportés: #{e.message}"
      nil
    end
  end
  
  private
  
  def download_temp_file(document)
    temp_file = Tempfile.new([document.title.parameterize, File.extname(document.file.filename.to_s)])
    temp_file.binmode
    
    document.file.open do |file|
      temp_file.write(file.read)
    end
    
    temp_file.rewind
    temp_file
  end
  
  def call_processor_api(temp_file, document)
    # Détermination des options de traitement basées sur le type de document
    processing_options = determine_processing_options(document)
    
    # Préparation de la requête multipart
    response = self.class.post('/process', {
      body: {
        file: temp_file,
        **processing_options
      },
      timeout: @timeout * 3 # Plus de temps pour le traitement
    })
    
    if response.success?
      response.parsed_response
    else
      { 'status' => 'error', 'detail' => "#{response.code}: #{response.body}" }
    end
  end
  
  def determine_processing_options(document)
    file_extension = File.extname(document.file.filename.to_s).downcase
    
    options = {
      extract_text: true,
      classify_document: true,
      extract_entities: true,
      language: 'fr'
    }
    
    # OCR pour les images et PDFs scannés
    if %w[.png .jpg .jpeg .tiff .bmp .gif].include?(file_extension)
      options[:perform_ocr] = true
    elsif file_extension == '.pdf'
      # OCR conditionnel pour les PDFs (sera déterminé par le service)
      options[:perform_ocr] = true
    end
    
    # Résumé pour les documents longs
    if %w[.pdf .docx .doc .txt].include?(file_extension)
      options[:generate_summary] = true
    end
    
    options
  end
  
  def update_document_with_ai_results(document, result)
    # Mise à jour du contenu textuel
    if result['text_content'].present?
      document.update_column(:extracted_text, result['text_content'])
    end
    
    # Classification du document
    if result['classification'].present?
      update_document_classification(document, result['classification'])
    end
    
    # Entités extraites
    if result['entities'].present?
      store_extracted_entities(document, result['entities'])
    end
    
    # Résumé
    if result['summary'].present?
      document.update_column(:ai_summary, result['summary'])
    end
    
    # Métadonnées de traitement
    processing_metadata = {
      processing_time: result['processing_time'],
      file_type_detected: result['file_type'],
      ai_metadata: result['metadata'],
      processed_at: Time.current
    }
    
    document.update(
      processing_status: 'completed',
      processing_metadata: processing_metadata,
      ai_processed_at: Time.current
    )
  end
  
  def update_document_classification(document, classification)
    # Classification par mots-clés
    if classification['keyword_classification'].present?
      keyword_class = classification['keyword_classification']
      document.update_column(:ai_category, keyword_class['top_category'])
      document.update_column(:ai_confidence, keyword_class['confidence'])
    end
    
    # Classification ML si disponible
    if classification['ml_classification'].present?
      ml_class = classification['ml_classification']
      # Préférer la classification ML si plus confiante
      if ml_class['confidence'] > (document.ai_confidence || 0)
        document.update_column(:ai_category, ml_class['category'])
        document.update_column(:ai_confidence, ml_class['confidence'])
      end
    end
    
    # Stockage de toutes les données de classification
    document.update_column(:ai_classification_data, classification)
  end
  
  def store_extracted_entities(document, entities)
    # Suppression des anciennes entités
    document.extracted_entities.destroy_all if document.respond_to?(:extracted_entities)
    
    # Création des nouvelles entités (si le modèle existe)
    entities.each do |entity_data|
      # Stocker dans les métadonnées pour le moment
      # Plus tard, vous pourriez créer un modèle ExtractedEntity
      next unless entity_data['confidence'] > 0.5 # Seuil de confiance
      
      # Pour l'instant, stockage dans un champ JSON
      current_entities = document.ai_entities || []
      current_entities << {
        type: entity_data['type'],
        value: entity_data['value'],
        confidence: entity_data['confidence'],
        position: [entity_data['start'], entity_data['end']],
        extracted_at: Time.current
      }
      
      document.update_column(:ai_entities, current_entities)
    end
  end
end