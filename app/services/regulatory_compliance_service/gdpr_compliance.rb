module RegulatoryComplianceService::GdprCompliance
  extend ActiveSupport::Concern
  
  class_methods do
    def check_personal_data(content)
      # Pattern de détection de données personnelles
      personal_data_patterns = [
        /\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}\b/, # Dates de naissance
        /\b\d{2}\s*\d{2}\s*\d{2}\s*\d{2}\s*\d{3}\s*\d{3}\s*\d{2}\b/, # Numéro de sécurité sociale
        /\b\w+@\w+\.\w+\b/, # Email
        /\b(?:\+33|0)[1-9](?:[0-9]{8})\b/, # Numéro de téléphone français
        /\b\d{1,3}\s+\w+\s+(?:rue|avenue|boulevard|place)\b/i # Adresses
      ]
      
      violations = []
      personal_data_patterns.each_with_index do |pattern, index|
        matches = content.scan(pattern)
        if matches.any?
          violations << {
            type: 'personal_data_exposure',
            description: "Données personnelles détectées (type #{index + 1})",
            locations: matches,
            severity: 'high'
          }
        end
      end
      
      violations
    end

    def check_consent_mention(content)
      consent_keywords = [
        'consentement', 'consent', 'accepte', 'agree',
        'autorisation', 'authorization', 'rgpd', 'gdpr'
      ]
      
      violations = []
      
      # Vérifier la présence de mentions de consentement
      has_consent = consent_keywords.any? { |keyword| content.downcase.include?(keyword) }
      
      unless has_consent
        violations << {
          type: 'missing_consent',
          description: 'Aucune mention de consentement RGPD trouvée',
          severity: 'medium',
          remediation: 'Ajouter une clause de consentement explicite'
        }
      end
      
      violations
    end

    def check_retention_policy(content)
      retention_keywords = [
        'conservation', 'retention', 'durée', 'duration',
        'suppression', 'deletion', 'archivage', 'archival'
      ]
      
      violations = []
      
      # Vérifier la présence de politique de conservation
      has_retention_policy = retention_keywords.any? { |keyword| content.downcase.include?(keyword) }
      
      unless has_retention_policy
        violations << {
          type: 'missing_retention_policy',
          description: 'Politique de conservation des données non spécifiée',
          severity: 'medium',
          remediation: 'Spécifier la durée de conservation des données'
        }
      end
      
      violations
    end
  end
  
  # Instance methods for GDPR compliance checking
  def check_gdpr_compliance
    return { score: 100, violations: [] } unless @content
    
    violations = []
    violations.concat(self.class.check_personal_data(@content))
    violations.concat(self.class.check_consent_mention(@content))
    violations.concat(self.class.check_retention_policy(@content))
    
    # Calculer le score GDPR
    score = 100
    violations.each do |violation|
      case violation[:severity]
      when 'high'
        score -= 30
      when 'medium'
        score -= 15
      when 'low'
        score -= 5
      end
    end
    
    {
      score: [score, 0].max,
      violations: violations,
      passed: violations.empty?
    }
  end
  
  private
  
  def contains_personal_data?(text)
    return false unless text
    
    # Extended patterns for personal data detection
    patterns = [
      /\b\d{2}[\s\-\/]\d{2}[\s\-\/]\d{4}\b/, # Date pattern
      /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/i, # Email
      /\b(?:\+33|0)[1-9](?:[0-9]{8})\b/, # French phone number
      /\b\+\d{1,3}\d{9,}\b/, # International phone (like +33123456789)
      /\b\d{3}-\d{2}-\d{4}\b/, # SSN pattern (123-45-6789)
      /\bphone:\s*\+?\d+/i, # Phone with label
      /\bemail:\s*[^\s]+@[^\s]+/i # Email with label
    ]
    
    patterns.any? { |pattern| text.match?(pattern) }
  end
end