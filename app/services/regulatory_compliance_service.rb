class RegulatoryComplianceService
  # Compliance rules configuration
  COMPLIANCE_RULES = {
    gdpr: {
      name: 'GDPR/RGPD Compliance',
      description: 'Protection des données personnelles',
      rules: [
        {
          id: 'gdpr_personal_data',
          description: 'Détection de données personnelles non protégées',
          check: ->(document, content) { check_personal_data(content) },
          severity: 'high',
          remediation: 'Anonymiser ou chiffrer les données personnelles'
        },
        {
          id: 'gdpr_consent',
          description: 'Vérification de la mention de consentement',
          check: ->(document, content) { check_consent_mention(content) },
          severity: 'medium',
          remediation: 'Ajouter une clause de consentement RGPD'
        },
        {
          id: 'gdpr_retention',
          description: 'Vérification de la durée de conservation',
          check: ->(document, content) { check_retention_policy(content) },
          severity: 'medium',
          remediation: 'Spécifier la durée de conservation des données'
        }
      ]
    },
    financial: {
      name: 'Financial Compliance',
      description: 'Conformité financière et anti-blanchiment',
      rules: [
        {
          id: 'fin_kyc',
          description: 'Vérification KYC (Know Your Customer)',
          check: ->(document, content) { check_kyc_requirements(document, content) },
          severity: 'high',
          remediation: 'Compléter les informations KYC requises'
        },
        {
          id: 'fin_transaction_limits',
          description: 'Vérification des limites de transaction',
          check: ->(document, content) { check_transaction_limits(content) },
          severity: 'medium',
          remediation: 'Vérifier les montants déclarés'
        }
      ]
    },
    environmental: {
      name: 'Environmental Compliance',
      description: 'Conformité environnementale',
      rules: [
        {
          id: 'env_impact_assessment',
          description: 'Évaluation d\'impact environnemental',
          check: ->(document, content) { check_environmental_impact(content) },
          severity: 'medium',
          remediation: 'Inclure une évaluation d\'impact environnemental'
        },
        {
          id: 'env_waste_management',
          description: 'Plan de gestion des déchets',
          check: ->(document, content) { check_waste_management(content) },
          severity: 'low',
          remediation: 'Ajouter un plan de gestion des déchets'
        }
      ]
    },
    contractual: {
      name: 'Contractual Compliance',
      description: 'Conformité contractuelle',
      rules: [
        {
          id: 'contract_signatures',
          description: 'Vérification des signatures',
          check: ->(document, content) { check_signatures(document, content) },
          severity: 'high',
          remediation: 'Obtenir toutes les signatures requises'
        },
        {
          id: 'contract_terms',
          description: 'Vérification des clauses obligatoires',
          check: ->(document, content) { check_mandatory_clauses(content) },
          severity: 'medium',
          remediation: 'Ajouter les clauses contractuelles manquantes'
        }
      ]
    },
    construction: {
      name: 'Construction/Real Estate Compliance',
      description: 'Conformité construction et immobilier',
      rules: [
        {
          id: 'permit_validity',
          description: 'Validité des permis de construire',
          check: ->(document, content) { check_permit_validity(document, content) },
          severity: 'high',
          remediation: 'Vérifier la validité et les dates des permis'
        },
        {
          id: 'safety_requirements',
          description: 'Exigences de sécurité',
          check: ->(document, content) { check_safety_requirements(content) },
          severity: 'high',
          remediation: 'Inclure les mesures de sécurité obligatoires'
        }
      ]
    }
  }.freeze
  
  def initialize(document)
    @document = document
    @violations = []
    @compliance_score = 100
  end
  
  def check_compliance
    return { compliant: true, score: 100, violations: [] } unless @document.file.attached?
    
    content = extract_document_content
    
    # Determine applicable compliance categories based on document type
    applicable_categories = determine_applicable_categories
    
    # Run compliance checks
    applicable_categories.each do |category|
      check_category_compliance(category, content)
    end
    
    # Calculate final score
    calculate_compliance_score
    
    # Store results
    store_compliance_results
    
    {
      compliant: @violations.empty?,
      score: @compliance_score,
      violations: @violations,
      checked_categories: applicable_categories,
      timestamp: Time.current
    }
  end
  
  def self.check_document_compliance(document)
    new(document).check_compliance
  end
  
  def self.bulk_compliance_check(documents)
    results = {}
    documents.find_each do |document|
      results[document.id] = check_document_compliance(document)
    end
    results
  end
  
  private
  
  def extract_document_content
    content = @document.extracted_text || ''
    content += " #{@document.title} #{@document.description}"
    
    # Include metadata
    if @document.metadata.any?
      content += " " + @document.metadata.map { |m| "#{m.key} #{m.value}" }.join(' ')
    end
    
    content
  end
  
  def determine_applicable_categories
    categories = []
    
    # Based on document category
    case @document.ai_category
    when 'contract'
      categories << :contractual << :gdpr
    when 'permit'
      categories << :construction << :environmental
    when 'invoice', 'financial'
      categories << :financial
    when 'report'
      categories << :environmental if @document.tags.any? { |t| t.name.include?('environmental') }
    end
    
    # Always check GDPR for documents containing personal data
    if @document.ai_entities&.any? { |e| ['email', 'phone'].include?(e['type']) }
      categories << :gdpr unless categories.include?(:gdpr)
    end
    
    categories.uniq
  end
  
  def check_category_compliance(category, content)
    rules = COMPLIANCE_RULES[category]
    return unless rules
    
    rules[:rules].each do |rule|
      begin
        result = instance_exec(@document, content, &rule[:check])
        
        if result[:violation]
          @violations << {
            category: category,
            rule_id: rule[:id],
            description: rule[:description],
            severity: rule[:severity],
            details: result[:details],
            remediation: rule[:remediation]
          }
        end
      rescue => e
        Rails.logger.error "Compliance check error for rule #{rule[:id]}: #{e.message}"
      end
    end
  end
  
  # Specific compliance check methods
  def self.check_personal_data(content)
    # Check for unprotected personal data
    personal_data_patterns = [
      /\b\d{13,15}\b/, # Social security numbers
      /\b(?:\d{4}[\s\-]?){3}\d{4}\b/, # Credit card numbers
      /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/ # Emails
    ]
    
    violations = []
    personal_data_patterns.each do |pattern|
      matches = content.scan(pattern)
      violations.concat(matches) if matches.any?
    end
    
    {
      violation: violations.any?,
      details: violations.any? ? "Données personnelles non protégées détectées: #{violations.count} occurrences" : nil
    }
  end
  
  def self.check_consent_mention(content)
    consent_keywords = ['consentement', 'consent', 'autorisation', 'accord explicite', 'rgpd', 'gdpr']
    has_consent = consent_keywords.any? { |keyword| content.downcase.include?(keyword) }
    
    {
      violation: !has_consent,
      details: has_consent ? nil : "Aucune mention de consentement RGPD trouvée"
    }
  end
  
  def self.check_retention_policy(content)
    retention_keywords = ['conservation', 'retention', 'durée', 'archivage', 'suppression']
    has_retention = retention_keywords.any? { |keyword| content.downcase.include?(keyword) }
    
    {
      violation: !has_retention,
      details: has_retention ? nil : "Aucune politique de conservation des données spécifiée"
    }
  end
  
  def self.check_kyc_requirements(document, content)
    required_fields = ['nom', 'adresse', 'date de naissance', 'pièce d\'identité']
    missing_fields = required_fields.reject { |field| content.downcase.include?(field) }
    
    {
      violation: missing_fields.any?,
      details: missing_fields.any? ? "Informations KYC manquantes: #{missing_fields.join(', ')}" : nil
    }
  end
  
  def self.check_transaction_limits(content)
    # Extract amounts and check against limits
    amounts = content.scan(/(\d{1,3}(?:\s?\d{3})*(?:,\d{2})?)\s*(?:€|EUR)/i).map do |match|
      match[0].gsub(/\s/, '').gsub(',', '.').to_f
    end
    
    high_amounts = amounts.select { |amount| amount > 10000 }
    
    {
      violation: high_amounts.any?,
      details: high_amounts.any? ? "Transactions élevées détectées: #{high_amounts.map { |a| "#{a}€" }.join(', ')}" : nil
    }
  end
  
  def self.check_environmental_impact(content)
    impact_keywords = ['impact environnemental', 'évaluation environnementale', 'étude d\'impact']
    has_impact = impact_keywords.any? { |keyword| content.downcase.include?(keyword) }
    
    {
      violation: !has_impact,
      details: has_impact ? nil : "Aucune évaluation d'impact environnemental trouvée"
    }
  end
  
  def self.check_waste_management(content)
    waste_keywords = ['déchets', 'recyclage', 'élimination', 'traitement des déchets']
    has_waste_plan = waste_keywords.any? { |keyword| content.downcase.include?(keyword) }
    
    {
      violation: !has_waste_plan,
      details: has_waste_plan ? nil : "Aucun plan de gestion des déchets spécifié"
    }
  end
  
  def self.check_signatures(document, content)
    signature_keywords = ['signature', 'signé', 'paraphe']
    has_signature_mention = signature_keywords.any? { |keyword| content.downcase.include?(keyword) }
    
    # For contracts, check if actually signed
    if document.ai_category == 'contract'
      {
        violation: !has_signature_mention,
        details: has_signature_mention ? nil : "Signatures requises non trouvées"
      }
    else
      { violation: false }
    end
  end
  
  def self.check_mandatory_clauses(content)
    mandatory_clauses = ['force majeure', 'résiliation', 'juridiction', 'loi applicable']
    missing_clauses = mandatory_clauses.reject { |clause| content.downcase.include?(clause) }
    
    {
      violation: missing_clauses.any?,
      details: missing_clauses.any? ? "Clauses obligatoires manquantes: #{missing_clauses.join(', ')}" : nil
    }
  end
  
  def self.check_permit_validity(document, content)
    # Check for expiry dates in permits
    date_pattern = /valable jusqu'au\s+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/i
    expiry_dates = content.scan(date_pattern).map { |match| Date.parse(match[0]) rescue nil }.compact
    
    expired_dates = expiry_dates.select { |date| date < Date.current }
    
    {
      violation: expired_dates.any?,
      details: expired_dates.any? ? "Permis expiré(s) détecté(s): #{expired_dates.map(&:to_s).join(', ')}" : nil
    }
  end
  
  def self.check_safety_requirements(content)
    safety_keywords = ['sécurité', 'prévention', 'protection', 'risque', 'danger', 'epi']
    has_safety = safety_keywords.any? { |keyword| content.downcase.include?(keyword) }
    
    {
      violation: !has_safety,
      details: has_safety ? nil : "Aucune mention des exigences de sécurité"
    }
  end
  
  def calculate_compliance_score
    return if @violations.empty?
    
    # Deduct points based on severity
    @violations.each do |violation|
      case violation[:severity]
      when 'high'
        @compliance_score -= 20
      when 'medium'
        @compliance_score -= 10
      when 'low'
        @compliance_score -= 5
      end
    end
    
    @compliance_score = [@compliance_score, 0].max # Don't go below 0
  end
  
  def store_compliance_results
    compliance_data = {
      score: @compliance_score,
      violations: @violations,
      checked_at: Time.current,
      compliant: @violations.empty?
    }
    
    # Store in document metadata
    @document.add_metadata('compliance_check', compliance_data.to_json)
    
    # Add compliance tags if violations found
    if @violations.any?
      @document.tags << Tag.find_or_create_by(name: 'compliance:non-compliant')
      
      # Add severity tags
      severities = @violations.map { |v| v[:severity] }.uniq
      severities.each do |severity|
        @document.tags << Tag.find_or_create_by(name: "compliance:#{severity}-risk")
      end
    else
      @document.tags << Tag.find_or_create_by(name: 'compliance:compliant')
    end
  end
  
  # Method to generate compliance report
  def self.generate_compliance_report(documents)
    report = {
      total_documents: documents.count,
      compliant_documents: 0,
      non_compliant_documents: 0,
      average_score: 0,
      violations_by_category: {},
      violations_by_severity: { high: 0, medium: 0, low: 0 }
    }
    
    total_score = 0
    
    documents.find_each do |document|
      result = check_document_compliance(document)
      
      if result[:compliant]
        report[:compliant_documents] += 1
      else
        report[:non_compliant_documents] += 1
      end
      
      total_score += result[:score]
      
      result[:violations].each do |violation|
        report[:violations_by_category][violation[:category]] ||= 0
        report[:violations_by_category][violation[:category]] += 1
        report[:violations_by_severity][violation[:severity].to_sym] += 1
      end
    end
    
    report[:average_score] = (total_score.to_f / documents.count).round(2) if documents.any?
    report
  end
end