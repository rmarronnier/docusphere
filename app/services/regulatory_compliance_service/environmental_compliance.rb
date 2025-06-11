module RegulatoryComplianceService::EnvironmentalCompliance
  extend ActiveSupport::Concern
  
  class_methods do
    def check_environmental_impact(content)
      violations = []
      
      # Mots-clés environnementaux obligatoires
      environmental_keywords = {
        impact_assessment: ['impact environnemental', 'évaluation environnementale', 'environmental impact'],
        emissions: ['émissions', 'emissions', 'co2', 'carbone', 'gaz à effet de serre'],
        waste: ['déchets', 'waste', 'recyclage', 'recycling'],
        energy: ['énergie', 'energy', 'consommation énergétique', 'efficiency']
      }
      
      environmental_keywords.each do |category, keywords|
        has_category = keywords.any? { |keyword| content.downcase.include?(keyword) }
        
        unless has_category
          violations << {
            type: 'missing_environmental_assessment',
            description: "Évaluation environnementale manquante: #{category}",
            severity: 'medium',
            remediation: "Ajouter une évaluation de l'impact #{category}"
          }
        end
      end
      
      # Vérifier la présence de mesures compensatoires
      compensation_keywords = ['compensation', 'mesures compensatoires', 'mitigation', 'offset']
      has_compensation = compensation_keywords.any? { |keyword| content.downcase.include?(keyword) }
      
      unless has_compensation
        violations << {
          type: 'missing_compensation_measures',
          description: 'Mesures compensatoires environnementales non mentionnées',
          severity: 'medium',
          remediation: 'Définir des mesures compensatoires'
        }
      end
      
      violations
    end

    def check_waste_management(content)
      violations = []
      
      waste_categories = [
        'déchets dangereux', 'hazardous waste',
        'déchets organiques', 'organic waste',
        'déchets recyclables', 'recyclable waste'
      ]
      
      # Vérifier la mention de chaque catégorie de déchets
      missing_categories = waste_categories.reject do |category|
        content.downcase.include?(category)
      end
      
      if missing_categories.any?
        violations << {
          type: 'incomplete_waste_management',
          description: "Catégories de déchets non traitées: #{missing_categories.join(', ')}",
          severity: 'medium',
          remediation: 'Compléter le plan de gestion des déchets'
        }
      end
      
      # Vérifier la présence d'un plan de gestion
      management_keywords = ['plan de gestion', 'management plan', 'traitement', 'treatment']
      has_management_plan = management_keywords.any? { |keyword| content.downcase.include?(keyword) }
      
      unless has_management_plan
        violations << {
          type: 'missing_waste_management_plan',
          description: 'Plan de gestion des déchets non spécifié',
          severity: 'high',
          remediation: 'Élaborer un plan de gestion des déchets'
        }
      end
      
      violations
    end
  end
  
  # Instance methods for environmental compliance checking
  def check_environmental_compliance
    return { score: 100, violations: [], passed: true } unless @content
    
    violations = []
    violations.concat(self.class.check_environmental_impact(@content))
    violations.concat(self.class.check_waste_management(@content))
    
    # Calculer le score basé sur le nombre et la gravité des violations
    score = 100
    violations.each do |violation|
      case violation[:severity]
      when 'high'
        score -= 25
      when 'medium'
        score -= 15
      when 'low'
        score -= 10
      end
    end
    
    {
      score: [score, 0].max,
      violations: violations,
      passed: violations.empty?
    }
  end
end