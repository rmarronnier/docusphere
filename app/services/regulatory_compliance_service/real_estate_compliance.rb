module RegulatoryComplianceService::RealEstateCompliance
  extend ActiveSupport::Concern
  
  class_methods do
    def check_permit_validity(document, content)
      violations = []
      
      # Types de permis immobiliers
      permit_types = [
        'permis de construire', 'building permit', 'construction permit',
        'permis d\'aménager', 'development permit',
        'déclaration préalable', 'prior declaration',
        'autorisation de travaux', 'work authorization'
      ]
      
      # Vérifier la mention de permis
      has_permit_mention = permit_types.any? { |permit| content.downcase.include?(permit) }
      
      if has_permit_mention
        # Vérifier les éléments obligatoires d'un permis
        permit_elements = {
          'numéro de permis' => ['numéro', 'number', 'référence', 'ref'],
          'date de délivrance' => ['délivré', 'issued', 'accordé', 'granted'],
          'autorité compétente' => ['mairie', 'préfecture', 'city hall', 'municipality'],
          'date d\'expiration' => ['expire', 'expiration', 'validité', 'validity']
        }
        
        permit_elements.each do |element, keywords|
          has_element = keywords.any? { |keyword| content.downcase.include?(keyword) }
          
          unless has_element
            violations << {
              type: 'incomplete_permit_info',
              description: "Information de permis manquante: #{element}",
              severity: 'high',
              remediation: "Spécifier #{element} du permis"
            }
          end
        end
      else
        violations << {
          type: 'missing_permit_reference',
          description: 'Aucune référence de permis trouvée',
          severity: 'high',
          remediation: 'Ajouter les références des permis nécessaires'
        }
      end
      
      violations
    end

    def check_safety_requirements(content)
      violations = []
      
      # Exigences de sécurité obligatoires
      safety_requirements = {
        'incendie' => ['sécurité incendie', 'fire safety', 'détecteur', 'detector', 'extincteur'],
        'accessibilité' => ['accessibilité', 'accessibility', 'handicapé', 'disabled', 'pmr'],
        'isolation' => ['isolation', 'insulation', 'thermique', 'thermal', 'phonique'],
        'ventilation' => ['ventilation', 'aération', 'air', 'vmc'],
        'électricité' => ['électrique', 'electrical', 'consuel', 'norme électrique']
      }
      
      safety_requirements.each do |category, keywords|
        has_requirement = keywords.any? { |keyword| content.downcase.include?(keyword) }
        
        unless has_requirement
          violations << {
            type: 'missing_safety_requirement',
            description: "Exigence de sécurité manquante: #{category}",
            severity: 'medium',
            remediation: "Ajouter les spécifications de sécurité #{category}"
          }
        end
      end
      
      # Vérifier les normes et certifications
      standards = ['norme', 'standard', 'certification', 'rt2012', 'rt2020', 'bbc', 'hqe']
      has_standards = standards.any? { |standard| content.downcase.include?(standard) }
      
      unless has_standards
        violations << {
          type: 'missing_standards',
          description: 'Aucune norme ou certification mentionnée',
          severity: 'medium',
          remediation: 'Spécifier les normes et certifications applicables'
        }
      end
      
      violations
    end
  end
  
  # Instance methods for real estate compliance checking
  def check_real_estate_compliance
    return [] unless @content
    
    violations = []
    violations.concat(self.class.check_permit_validity(@document, @content))
    violations.concat(self.class.check_safety_requirements(@content))
    
    violations
  end
end