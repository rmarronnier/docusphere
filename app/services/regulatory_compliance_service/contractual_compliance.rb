module RegulatoryComplianceService::ContractualCompliance
  extend ActiveSupport::Concern
  
  class_methods do
    def check_signatures(document, content)
      violations = []
      
      # Vérifier la présence de mentions de signature
      signature_keywords = [
        'signature', 'signé', 'signed', 'signature électronique',
        'electronic signature', 'paraphé', 'initialed'
      ]
      
      has_signature_mention = signature_keywords.any? { |keyword| content.downcase.include?(keyword) }
      
      unless has_signature_mention
        violations << {
          type: 'missing_signature',
          description: 'Aucune mention de signature trouvée',
          severity: 'high',
          remediation: 'Ajouter des clauses de signature'
        }
      end
      
      # Vérifier la validité des signatures électroniques si mentionnées
      if content.downcase.include?('signature électronique')
        electronic_sig_requirements = [
          'certificat', 'certificate', 'horodatage', 'timestamp',
          'autorité de certification', 'certification authority'
        ]
        
        missing_requirements = electronic_sig_requirements.reject do |req|
          content.downcase.include?(req)
        end
        
        if missing_requirements.any?
          violations << {
            type: 'incomplete_electronic_signature',
            description: "Éléments manquants pour signature électronique: #{missing_requirements.join(', ')}",
            severity: 'medium',
            remediation: 'Compléter les exigences de signature électronique'
          }
        end
      end
      
      violations
    end

    def check_mandatory_clauses(content)
      violations = []
      
      # Clauses obligatoires selon le type de contrat
      mandatory_clauses = {
        'force majeure' => ['force majeure', 'cas fortuit', 'circumstances beyond control'],
        'résiliation' => ['résiliation', 'termination', 'rupture', 'annulation'],
        'responsabilité' => ['responsabilité', 'liability', 'responsable'],
        'confidentialité' => ['confidentialité', 'confidentiality', 'secret', 'non-disclosure'],
        'propriété intellectuelle' => ['propriété intellectuelle', 'intellectual property', 'copyright', 'droit d\'auteur']
      }
      
      mandatory_clauses.each do |clause_type, keywords|
        has_clause = keywords.any? { |keyword| content.downcase.include?(keyword) }
        
        unless has_clause
          violations << {
            type: 'missing_mandatory_clause',
            description: "Clause obligatoire manquante: #{clause_type}",
            severity: 'medium',
            remediation: "Ajouter une clause de #{clause_type}"
          }
        end
      end
      
      # Vérifier la présence de dates et durées
      date_patterns = [
        /\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}\b/,
        /\b\d{1,2}\s+(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{4}\b/i
      ]
      
      has_dates = date_patterns.any? { |pattern| content.match?(pattern) }
      
      unless has_dates
        violations << {
          type: 'missing_dates',
          description: 'Aucune date ou échéance spécifiée',
          severity: 'medium',
          remediation: 'Spécifier les dates et échéances contractuelles'
        }
      end
      
      violations
    end
  end
  
  # Instance methods for contractual compliance checking
  def check_contractual_compliance
    return [] unless @content
    
    violations = []
    violations.concat(self.class.check_signatures(@document, @content))
    violations.concat(self.class.check_mandatory_clauses(@content))
    
    violations
  end
end