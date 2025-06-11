module RegulatoryComplianceService::CoreOperations
  extend ActiveSupport::Concern
  
  class_methods do
    def check_document_compliance(document)
      service = RegulatoryComplianceService.new(document)
      service.check_compliance
    end
    
    def bulk_compliance_check(documents)
      results = {}
      
      documents.each do |document|
        begin
          results[document.id] = check_document_compliance(document)
        rescue => e
          results[document.id] = {
            error: e.message,
            compliance_score: 0,
            violations: []
          }
        end
      end
      
      results
    end
    
    def generate_compliance_report(documents)
      results = bulk_compliance_check(documents)
      
      total_documents = documents.count
      compliant_documents = results.values.count { |result| !result.key?(:error) && result[:compliance_score] >= 80 }
      
      violations_by_type = Hash.new(0)
      results.values.each do |result|
        next if result.key?(:error)
        result[:violations].each do |violation|
          violations_by_type[violation[:type]] += 1
        end
      end
      
      {
        summary: {
          total_documents: total_documents,
          compliant_documents: compliant_documents,
          compliance_rate: (compliant_documents.to_f / total_documents * 100).round(2),
          average_score: results.values.reject { |r| r.key?(:error) }.map { |r| r[:compliance_score] }.sum / total_documents.to_f
        },
        violations_summary: violations_by_type,
        detailed_results: results,
        generated_at: Time.current
      }
    end
  end
  
  # Instance methods for core operations
  def check_compliance
    @compliance_results = {
      document_id: @document.id,
      checks: [],
      violations: [],
      compliance_score: 0,
      checked_at: Time.current
    }
    
    # Déterminer les catégories applicables
    applicable_categories = determine_applicable_categories
    
    # Effectuer les vérifications pour chaque catégorie
    applicable_categories.each do |category|
      violations = check_category_compliance(category, @content)
      @compliance_results[:violations].concat(violations)
      @compliance_results[:checks] << {
        category: category,
        violations_count: violations.count,
        passed: violations.empty?
      }
    end
    
    # Calculer le score de conformité
    @compliance_results[:compliance_score] = calculate_compliance_score
    
    # Stocker les résultats
    store_compliance_results
    
    @compliance_results
  end
  
  private
  
  def extract_document_content
    @content = if @document.respond_to?(:content) && @document.content.present?
                 @document.content
               elsif @document.respond_to?(:extracted_content) && @document.extracted_content.present?
                 @document.extracted_content
               else
                 # Fallback: essayer d'extraire du titre et de la description
                 [@document.title, @document.description].compact.join(' ')
               end
    
    @content ||= ''
  end
  
  def determine_applicable_categories
    categories = []
    
    # Analyser le contenu et le type de document pour déterminer les catégories
    content_lower = @content.downcase
    
    # GDPR si données personnelles suspectées
    if contains_personal_data?(@content)
      categories << :gdpr
    end
    
    # Financier si montants détectés
    if extract_amounts(@content).any?
      categories << :financial
    end
    
    # Environnemental si mots-clés environnementaux
    env_keywords = ['environnement', 'écologie', 'pollution', 'émission', 'déchets']
    if env_keywords.any? { |keyword| content_lower.include?(keyword) }
      categories << :environmental
    end
    
    # Contractuel si structure de contrat
    contract_keywords = ['contrat', 'accord', 'convention', 'clause', 'partie']
    if contract_keywords.any? { |keyword| content_lower.include?(keyword) }
      categories << :contractual
    end
    
    # Immobilier si mots-clés immobiliers
    real_estate_keywords = ['permis', 'construction', 'bâtiment', 'immobilier', 'terrain']
    if real_estate_keywords.any? { |keyword| content_lower.include?(keyword) }
      categories << :real_estate
    end
    
    # Par défaut, au moins contractuel si rien d'autre n'est détecté
    categories << :contractual if categories.empty?
    
    categories.uniq
  end
  
  def check_category_compliance(category, content)
    case category
    when :gdpr
      check_gdpr_compliance
    when :financial
      check_financial_compliance
    when :environmental
      check_environmental_compliance
    when :contractual
      check_contractual_compliance
    when :real_estate
      check_real_estate_compliance
    else
      []
    end
  end
  
  def calculate_compliance_score
    return 100 if @compliance_results[:violations].empty?
    
    total_violations = @compliance_results[:violations].count
    high_severity_violations = @compliance_results[:violations].count { |v| v[:severity] == 'high' }
    medium_severity_violations = @compliance_results[:violations].count { |v| v[:severity] == 'medium' }
    low_severity_violations = @compliance_results[:violations].count { |v| v[:severity] == 'low' }
    
    # Pondération des violations
    weighted_score = 100 - (high_severity_violations * 20 + medium_severity_violations * 10 + low_severity_violations * 5)
    
    # S'assurer que le score reste entre 0 et 100
    [weighted_score, 0].max
  end
  
  def store_compliance_results
    # Créer ou mettre à jour l'enregistrement de conformité
    begin
      compliance_tag = Tag.find_or_create_by(
        name: "compliance_#{@compliance_results[:compliance_score]}",
        organization: @document.space&.organization || @document.uploaded_by&.organization
      ) do |tag|
        tag.color = @compliance_results[:compliance_score] >= 80 ? 'green' : 
                   @compliance_results[:compliance_score] >= 60 ? 'orange' : 'red'
      end
      
      # Associer le tag au document
      @document.tags << compliance_tag unless @document.tags.include?(compliance_tag)
    rescue => e
      Rails.logger.error "Erreur lors du stockage des résultats de conformité: #{e.message}"
    end
    
    # Stocker dans les métadonnées du document
    @document.update(
      processing_metadata: (@document.processing_metadata || {}).merge(
        compliance: @compliance_results
      )
    )
  end
  
  def calculate_overall_score(checks)
    return 100 if checks.empty?
    
    passed_checks = checks.count { |check| check[:passed] }
    (passed_checks.to_f / checks.count * 100).round(2)
  end
  
  def get_severity(violation_type)
    severity_mapping = {
      'personal_data_detected' => 'high',
      'missing_kyc_element' => 'high',
      'missing_permit_reference' => 'high',
      'missing_signature' => 'high',
      'missing_consent' => 'medium',
      'missing_retention_policy' => 'medium',
      'cash_limit_exceeded' => 'medium',
      'missing_environmental_assessment' => 'medium',
      'missing_safety_requirement' => 'medium',
      'missing_mandatory_clause' => 'medium'
    }
    
    severity_mapping[violation_type] || 'low'
  end
end