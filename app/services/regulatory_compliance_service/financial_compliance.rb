module RegulatoryComplianceService::FinancialCompliance
  extend ActiveSupport::Concern
  
  class_methods do
    def check_kyc_requirements(document, content)
      violations = []
      
      # Vérifications KYC de base
      kyc_elements = {
        identity: ['identité', 'identity', 'nom', 'name', 'prénom', 'firstname'],
        address: ['adresse', 'address', 'domicile', 'residence'],
        financial_status: ['revenus', 'income', 'patrimoine', 'assets', 'situation financière']
      }
      
      kyc_elements.each do |element, keywords|
        has_element = keywords.any? { |keyword| content.downcase.include?(keyword) }
        
        unless has_element
          violations << {
            type: 'missing_kyc_element',
            description: "Élément KYC manquant: #{element}",
            severity: 'high',
            remediation: "Ajouter les informations de #{element}"
          }
        end
      end
      
      # Vérifier la présence de documents justificatifs
      required_docs = ['pièce d\'identité', 'justificatif', 'proof', 'document']
      has_supporting_docs = required_docs.any? { |doc| content.downcase.include?(doc) }
      
      unless has_supporting_docs
        violations << {
          type: 'missing_supporting_documents',
          description: 'Aucun document justificatif mentionné',
          severity: 'medium',
          remediation: 'Joindre les pièces justificatives requises'
        }
      end
      
      violations
    end

    def check_transaction_limits(content)
      violations = []
      
      # Extraire les montants du contenu
      amounts = extract_amounts_from_content(content)
      
      # Seuils réglementaires (en euros)
      thresholds = {
        cash_limit: 1000,        # Limite paiement espèces
        declaration_limit: 10000  # Seuil de déclaration
      }
      
      amounts.each do |amount|
        if amount > thresholds[:declaration_limit]
          violations << {
            type: 'high_amount_transaction',
            description: "Montant élevé détecté: #{amount}€ (seuil: #{thresholds[:declaration_limit]}€)",
            severity: 'high',
            remediation: 'Vérifier les obligations déclaratives'
          }
        elsif amount > thresholds[:cash_limit]
          violations << {
            type: 'cash_limit_exceeded',
            description: "Montant supérieur à la limite espèces: #{amount}€",
            severity: 'medium',
            remediation: 'Vérifier le mode de paiement'
          }
        end
      end
      
      violations
    end
    
    private
    
    def extract_amounts_from_content(content)
      # Extraire les montants en euros du contenu
      amount_patterns = [
        /(\d{1,3}(?:\s*\d{3})*(?:[,\.]\d{2})?)\s*(?:€|euros?|EUR)/i,
        /(\d{1,3}(?:\s*\d{3})*(?:[,\.]\d{2})?)\s*(?:dollars?|USD|\$)/i
      ]
      
      amounts = []
      amount_patterns.each do |pattern|
        content.scan(pattern) do |match|
          # Nettoyer et convertir en nombre
          clean_amount = match[0].gsub(/\s/, '').gsub(',', '.').to_f
          amounts << clean_amount if clean_amount > 0
        end
      end
      
      amounts.uniq.sort.reverse # Trier par montant décroissant
    end
  end
  
  # Instance methods for financial compliance checking
  def check_financial_compliance
    return [] unless @content
    
    violations = []
    violations.concat(self.class.check_kyc_requirements(@document, @content))
    violations.concat(self.class.check_transaction_limits(@content))
    
    violations
  end
  
  private
  
  def extract_amounts(text)
    return [] unless text
    
    # Pattern plus simple pour les montants
    amounts = []
    
    # Recherche de montants en euros
    text.scan(/(\d+(?:[,\.]\d{2})?)\s*(?:€|euros?)/i) do |match|
      amount = match[0].gsub(',', '.').to_f
      amounts << amount if amount > 0
    end
    
    amounts
  end
end