class AutoTaggingJob < ApplicationJob
  queue_as :document_processing
  
  # Document type keywords
  DOCUMENT_TYPES = {
    'facture' => %w[facture invoice montant total ttc tva paiement échéance],
    'contrat' => %w[contrat contract accord convention parties signataire signature],
    'devis' => %w[devis estimation quote proposition prix coût],
    'bon_commande' => %w[commande order achat purchase fournisseur],
    'rapport' => %w[rapport report analyse étude conclusion recommandation],
    'courrier' => %w[madame monsieur cordialement sincèrement lettre],
    'cv' => %w[curriculum vitae expérience formation compétences diplôme],
    'compte_rendu' => %w[compte rendu réunion meeting présents ordre jour],
    'procédure' => %w[procédure procedure étape processus instruction],
    'manuel' => %w[manuel guide utilisation mode emploi instructions]
  }
  
  # Topic keywords
  TOPICS = {
    'finance' => %w[budget comptabilité trésorerie bilan résultat fiscal impôt],
    'juridique' => %w[légal juridique droit loi article code tribunal justice],
    'rh' => %w[employé salarié congé salaire embauche licenciement formation],
    'commercial' => %w[client vente achat produit service marketing prospect],
    'technique' => %w[technique spécification développement système architecture],
    'immobilier' => %w[immeuble appartement location vente bail locataire propriétaire]
  }
  
  def perform(document)
    return unless document.content.present?
    
    content_lower = document.content.downcase
    suggested_tags = Set.new
    
    # Detect document type
    document_type = detect_document_type(content_lower)
    suggested_tags << document_type if document_type
    
    # Detect topics
    topics = detect_topics(content_lower)
    suggested_tags.merge(topics)
    
    # Extract from metadata
    metadata_tags = extract_metadata_tags(document)
    suggested_tags.merge(metadata_tags)
    
    # Add status-based tags
    suggested_tags << 'urgent' if urgent_document?(content_lower)
    suggested_tags << 'confidentiel' if confidential_document?(content_lower)
    
    # Apply tags
    apply_tags(document, suggested_tags)
    
    # Apply metadata template if document type detected
    apply_metadata_template(document, document_type) if document_type
  end
  
  private
  
  def detect_document_type(content)
    DOCUMENT_TYPES.each do |type, keywords|
      score = keywords.count { |keyword| content.include?(keyword) }
      return type if score >= 2  # At least 2 keywords match
    end
    nil
  end
  
  def detect_topics(content)
    topics = []
    TOPICS.each do |topic, keywords|
      score = keywords.count { |keyword| content.include?(keyword) }
      topics << topic if score >= 2
    end
    topics
  end
  
  def extract_metadata_tags(document)
    tags = []
    
    # From extracted metadata
    if document.metadata.exists?(key: 'document_date')
      date = Date.parse(document.metadata.find_by(key: 'document_date').value)
      tags << date.year.to_s
      tags << "Q#{((date.month - 1) / 3) + 1}" # Quarter
    end
    
    # From amounts
    if document.metadata.exists?(key: 'total_amount')
      amount = document.metadata.find_by(key: 'total_amount').value.to_f
      tags << 'high_value' if amount > 10000
    end
    
    # From file type
    case document.file.content_type
    when /pdf/ then tags << 'pdf'
    when /word/ then tags << 'word'
    when /excel/ then tags << 'excel'
    when /image/ then tags << 'image'
    end
    
    tags
  end
  
  def urgent_document?(content)
    urgent_keywords = %w[urgent urgence immédiat prioritaire asap délai court importante]
    urgent_keywords.any? { |keyword| content.include?(keyword) }
  end
  
  def confidential_document?(content)
    confidential_keywords = %w[confidentiel secret privé restricted internal interne]
    confidential_keywords.any? { |keyword| content.include?(keyword) }
  end
  
  def apply_tags(document, suggested_tags)
    suggested_tags.each do |tag_name|
      tag = Tag.find_or_create_by(name: tag_name.downcase)
      document.tags << tag unless document.tags.include?(tag)
    end
  end
  
  def apply_metadata_template(document, document_type)
    # Find appropriate template
    template_name = case document_type
                   when 'facture' then 'Invoice Template'
                   when 'contrat' then 'Contract Template'
                   when 'rapport' then 'Report Template'
                   else return
                   end
    
    template = MetadataTemplate.find_by(
      name: template_name,
      organization: document.space.organization
    )
    
    return unless template
    
    # Apply template fields if not already present
    template.metadata_fields.each do |field|
      next if document.metadata.exists?(metadata_field: field)
      
      # Try to extract value based on field name
      value = extract_field_value(document, field)
      next unless value || field.is_required
      
      document.metadata.create!(
        metadata_field: field,
        key: field.name,
        value: value || ''
      )
    end
  end
  
  def extract_field_value(document, field)
    case field.name.downcase
    when 'author', 'auteur'
      document.user.full_name
    when 'department', 'département'
      document.metadata.find_by(key: 'department')&.value
    when 'date'
      document.metadata.find_by(key: 'document_date')&.value || Date.current.to_s
    when 'status'
      'Draft'
    else
      nil
    end
  end
end