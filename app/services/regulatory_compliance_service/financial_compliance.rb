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
      
      # Vérifier si c'est un paiement en espèces
      is_cash_payment = content.downcase.include?('cash') || content.downcase.include?('espèces')
      
      amounts.each do |amount|
        if amount > thresholds[:declaration_limit]
          violations << {
            type: 'high_amount_transaction',
            description: "Montant élevé détecté: #{amount}€ (seuil: #{thresholds[:declaration_limit]}€)",
            severity: 'high',
            remediation: 'Vérifier les obligations déclaratives'
          }
          
          # Si c'est un paiement cash de plus de 10000€, c'est aussi une violation spécifique
          if is_cash_payment
            violations << {
              type: 'large_cash_transaction',
              description: "Transaction en espèces importante: #{amount}€",
              severity: 'high',
              remediation: 'Les paiements en espèces supérieurs à 10,000€ nécessitent une déclaration'
            }
          end
        elsif amount > thresholds[:cash_limit] && is_cash_payment
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
        # Format: €15,000.00 or €15.000,00
        /€\s*(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)/i,
        # Format: 15,000.00€ or 15.000,00 euros
        /(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(?:€|euros?|EUR)/i,
        # Format: $15,000.00
        /\$\s*(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)/i,
        # Format: 15,000.00 dollars
        /(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(?:dollars?|USD|\$)/i
      ]
      
      amounts = []
      amount_patterns.each do |pattern|
        content.scan(pattern) do |match|
          # Nettoyer et convertir en nombre
          # Gérer les formats européens (1.000,00) et américains (1,000.00)
          clean_amount = match[0].gsub(/\s/, '')
          
          # Si on a des virgules et des points, déterminer lequel est le séparateur décimal
          if clean_amount.include?(',') && clean_amount.include?('.')
            # Si le dernier est une virgule, c'est le format européen
            if clean_amount.rindex(',') > clean_amount.rindex('.')
              clean_amount = clean_amount.gsub('.', '').gsub(',', '.')
            else
              # Sinon c'est le format américain
              clean_amount = clean_amount.gsub(',', '')
            end
          elsif clean_amount.include?(',')
            # Si on n'a que des virgules, déterminer si c'est décimal ou milliers
            parts = clean_amount.split(',')
            if parts.last.length == 2 && parts.length == 2
              # Probablement décimal
              clean_amount = clean_amount.gsub(',', '.')
            else
              # Probablement milliers
              clean_amount = clean_amount.gsub(',', '')
            end
          end
          
          amount = clean_amount.to_f
          amounts << amount if amount > 0
        end
      end
      
      amounts.uniq.sort.reverse # Trier par montant décroissant
    end
  end
  
  # Instance methods for financial compliance checking
  def check_financial_compliance
    return { score: 100, violations: [] } unless @content
    
    violations = []
    violations.concat(self.class.check_kyc_requirements(@document, @content))
    violations.concat(self.class.check_transaction_limits(@content))
    
    # Calculer le score financier
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
  
  def extract_amounts(text)
    return [] unless text
    
    amounts = []
    
    # Recherche de montants en euros avec format varié
    text.scan(/€\s*(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)|(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(?:€|euros?)/i) do |before, after|
      amount_str = (before || after).gsub(/[,\s]/, '').gsub('.', '')
      # Gérer les centimes
      if amount_str =~ /(\d+)(\d{2})$/
        amount = "#{$1}.#{$2}".to_f
      else
        amount = amount_str.to_f
      end
      amounts << amount if amount > 0
    end
    
    # Recherche de montants en dollars
    text.scan(/\$\s*(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)|(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(?:\$|dollars?)/i) do |before, after|
      amount_str = (before || after).gsub(/[,\s]/, '').gsub('.', '')
      # Gérer les centimes
      if amount_str =~ /(\d+)(\d{2})$/
        amount = "#{$1}.#{$2}".to_f
      else
        amount = amount_str.to_f
      end
      amounts << amount if amount > 0
    end
    
    amounts
  end
end