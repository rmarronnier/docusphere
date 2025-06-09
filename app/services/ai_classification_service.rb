class AiClassificationService
  # Document categories based on common business document types
  DOCUMENT_CATEGORIES = {
    'contract' => {
      keywords: ['contrat', 'accord', 'convention', 'engagement', 'clause', 'signataire', 'partie', 'obligation'],
      patterns: [/contrat\s+de/i, /accord\s+de/i, /convention\s+de/i],
      confidence_boost: 0.2
    },
    'invoice' => {
      keywords: ['facture', 'montant', 'tva', 'total', 'référence', 'échéance', 'paiement', 'ht', 'ttc'],
      patterns: [/facture\s+n°/i, /total\s+ttc/i, /montant\s+ht/i],
      confidence_boost: 0.3
    },
    'report' => {
      keywords: ['rapport', 'analyse', 'étude', 'synthèse', 'conclusion', 'recommandation', 'constat'],
      patterns: [/rapport\s+(de|d')/i, /synthèse\s+de/i],
      confidence_boost: 0.1
    },
    'permit' => {
      keywords: ['permis', 'autorisation', 'licence', 'agrément', 'certificat', 'habilitation'],
      patterns: [/permis\s+de/i, /autorisation\s+de/i],
      confidence_boost: 0.25
    },
    'specification' => {
      keywords: ['spécification', 'cahier', 'charges', 'technique', 'fonctionnel', 'exigence', 'besoin'],
      patterns: [/cahier\s+des\s+charges/i, /spécifications?\s+techniques?/i],
      confidence_boost: 0.2
    },
    'correspondence' => {
      keywords: ['lettre', 'courrier', 'mail', 'email', 'message', 'destinataire', 'expéditeur', 'objet'],
      patterns: [/objet\s*:/i, /madame|monsieur/i, /cordialement/i],
      confidence_boost: 0.1
    },
    'legal' => {
      keywords: ['juridique', 'légal', 'avocat', 'tribunal', 'jugement', 'article', 'loi', 'décret'],
      patterns: [/article\s+\d+/i, /tribunal\s+de/i, /code\s+de/i],
      confidence_boost: 0.2
    },
    'financial' => {
      keywords: ['financier', 'budget', 'compte', 'bilan', 'résultat', 'crédit', 'débit', 'solde'],
      patterns: [/bilan\s+financier/i, /compte\s+de\s+résultat/i],
      confidence_boost: 0.15
    },
    'technical' => {
      keywords: ['technique', 'schéma', 'plan', 'dessin', 'dimension', 'mesure', 'composant'],
      patterns: [/plan\s+technique/i, /schéma\s+de/i],
      confidence_boost: 0.1
    },
    'administrative' => {
      keywords: ['administratif', 'formulaire', 'déclaration', 'attestation', 'demande', 'dossier'],
      patterns: [/formulaire\s+de/i, /déclaration\s+de/i],
      confidence_boost: 0.05
    }
  }.freeze
  
  # Compliance-related keywords for regulatory checking
  COMPLIANCE_KEYWORDS = {
    'gdpr' => ['données personnelles', 'rgpd', 'gdpr', 'protection des données', 'consentement', 'vie privée'],
    'environmental' => ['environnement', 'écologique', 'pollution', 'émission', 'recyclage', 'développement durable'],
    'safety' => ['sécurité', 'risque', 'danger', 'prévention', 'accident', 'protection', 'epi'],
    'quality' => ['qualité', 'iso', 'norme', 'certification', 'conformité', 'audit', 'contrôle'],
    'financial_compliance' => ['blanchiment', 'fraude', 'compliance', 'régulation', 'déclaration', 'transparence']
  }.freeze
  
  def initialize(document)
    @document = document
  end
  
  def classify
    return unless @document.file.attached?
    
    # Get document content
    content = extract_content
    return if content.blank?
    
    # Perform classification
    classification_result = classify_content(content)
    
    # Extract entities
    entities = extract_entities(content)
    
    # Check compliance
    compliance_flags = check_compliance(content)
    
    # Update document with AI results
    update_document_ai_fields(classification_result, entities, compliance_flags)
    
    # Auto-tag document based on classification
    auto_tag_document(classification_result, entities, compliance_flags)
    
    true
  rescue => e
    Rails.logger.error "AI Classification failed for document #{@document.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end
  
  private
  
  def extract_content
    # Use existing extracted content if available
    if @document.extracted_text.present?
      return @document.extracted_text
    end
    
    # For now, use title and description
    # In production, this would use the actual OCR/text extraction
    content = [@document.title, @document.description].compact.join(' ')
    
    # If we have metadata, include it
    if @document.metadata.any?
      metadata_text = @document.metadata.map { |m| "#{m.key} #{m.value}" }.join(' ')
      content += " #{metadata_text}"
    end
    
    content
  end
  
  def classify_content(content)
    content_lower = content.downcase
    scores = {}
    
    DOCUMENT_CATEGORIES.each do |category, config|
      score = 0.0
      
      # Check keywords
      keyword_matches = config[:keywords].count { |keyword| content_lower.include?(keyword.downcase) }
      score += keyword_matches * 0.1
      
      # Check patterns
      pattern_matches = config[:patterns].count { |pattern| content =~ pattern }
      score += pattern_matches * 0.3
      
      # Apply confidence boost for strong indicators
      if keyword_matches > 2 || pattern_matches > 0
        score += config[:confidence_boost]
      end
      
      # Normalize score (0-1)
      score = [score, 1.0].min
      scores[category] = score
    end
    
    # Get top category
    top_category = scores.max_by { |_, score| score }
    
    {
      category: top_category[0],
      confidence: top_category[1],
      all_scores: scores
    }
  end
  
  def extract_entities(content)
    entities = []
    
    # Extract emails
    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
    content.scan(email_regex).each do |email|
      entities << {
        type: 'email',
        value: email,
        confidence: 0.95
      }
    end
    
    # Extract phone numbers (French format)
    phone_regex = /(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}/
    content.scan(phone_regex).each do |phone|
      entities << {
        type: 'phone',
        value: phone.strip,
        confidence: 0.85
      }
    end
    
    # Extract amounts/prices
    amount_regex = /\d{1,3}(?:\s?\d{3})*(?:,\d{2})?\s*(?:€|EUR|euros?)/i
    content.scan(amount_regex).each do |amount|
      entities << {
        type: 'amount',
        value: amount.strip,
        confidence: 0.9
      }
    end
    
    # Extract dates (French format)
    date_regex = /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/
    content.scan(date_regex).each do |date|
      entities << {
        type: 'date',
        value: date,
        confidence: 0.8
      }
    end
    
    # Extract company names (simplified - looks for SARL, SAS, SA, etc.)
    company_regex = /\b[A-Z][A-Za-z\s&\-]+(?:SARL|SAS|SA|SNC|EURL|SASU|GIE)\b/
    content.scan(company_regex).each do |company|
      entities << {
        type: 'organization',
        value: company.strip,
        confidence: 0.7
      }
    end
    
    # Extract reference numbers (invoice numbers, contract numbers, etc.)
    ref_regex = /(?:n°|N°|ref\.|référence)\s*:?\s*([A-Z0-9\-\/]+)/i
    content.scan(ref_regex).each do |ref|
      entities << {
        type: 'reference',
        value: ref[0],
        confidence: 0.75
      }
    end
    
    entities
  end
  
  def check_compliance(content)
    content_lower = content.downcase
    compliance_flags = []
    
    COMPLIANCE_KEYWORDS.each do |compliance_type, keywords|
      matches = keywords.count { |keyword| content_lower.include?(keyword.downcase) }
      if matches > 0
        compliance_flags << {
          type: compliance_type.to_s,
          severity: matches > 2 ? 'high' : 'medium',
          keyword_matches: matches
        }
      end
    end
    
    compliance_flags
  end
  
  def update_document_ai_fields(classification_result, entities, compliance_flags)
    @document.update_columns(
      ai_category: classification_result[:category],
      ai_confidence: classification_result[:confidence],
      ai_entities: entities,
      ai_classification_data: {
        scores: classification_result[:all_scores],
        compliance_flags: compliance_flags,
        processed_at: Time.current
      },
      ai_processed_at: Time.current
    )
  end
  
  def auto_tag_document(classification_result, entities, compliance_flags)
    tags_to_add = []
    
    # Add category tag
    if classification_result[:confidence] > 0.5
      tags_to_add << "type:#{classification_result[:category]}"
    end
    
    # Add compliance tags
    compliance_flags.each do |flag|
      if flag[:severity] == 'high'
        tags_to_add << "compliance:#{flag[:type]}"
      end
    end
    
    # Add entity-based tags
    if entities.any? { |e| e[:type] == 'amount' }
      tags_to_add << 'financial'
    end
    
    if entities.any? { |e| e[:type] == 'date' }
      tags_to_add << 'dated'
    end
    
    # Create or find tags and associate with document
    tags_to_add.uniq.each do |tag_name|
      tag = Tag.find_or_create_by(name: tag_name)
      @document.tags << tag unless @document.tags.include?(tag)
    end
  end
  
  # Public method to be called from jobs or controllers
  def self.classify_document(document)
    new(document).classify
  end
  
  # Batch classification for multiple documents
  def self.classify_documents(documents)
    results = {}
    documents.each do |document|
      results[document.id] = classify_document(document)
    end
    results
  end
  
  # Re-classify documents that match certain criteria
  def self.reclassify_documents(scope = Document.all)
    scope.find_each do |document|
      classify_document(document) if document.file.attached?
    end
  end
end