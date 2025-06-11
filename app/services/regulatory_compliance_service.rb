class RegulatoryComplianceService
  include RegulatoryComplianceService::CoreOperations
  include RegulatoryComplianceService::GdprCompliance
  include RegulatoryComplianceService::FinancialCompliance
  include RegulatoryComplianceService::EnvironmentalCompliance
  include RegulatoryComplianceService::ContractualCompliance
  include RegulatoryComplianceService::RealEstateCompliance
  
  # Compliance rules configuration
  COMPLIANCE_RULES = {
    gdpr: {
      name: 'GDPR/RGPD Compliance',
      description: 'Protection des données personnelles',
      rules: [
        {
          id: 'gdpr_personal_data',
          description: 'Détection de données personnelles non protégées',
          check: ->(document, content) { RegulatoryComplianceService.check_personal_data(content) },
          severity: 'high',
          remediation: 'Anonymiser ou chiffrer les données personnelles'
        },
        {
          id: 'gdpr_consent',
          description: 'Vérification de la mention de consentement',
          check: ->(document, content) { RegulatoryComplianceService.check_consent_mention(content) },
          severity: 'medium',
          remediation: 'Ajouter une clause de consentement RGPD'
        },
        {
          id: 'gdpr_retention',
          description: 'Vérification de la durée de conservation',
          check: ->(document, content) { RegulatoryComplianceService.check_retention_policy(content) },
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
          check: ->(document, content) { RegulatoryComplianceService.check_kyc_requirements(document, content) },
          severity: 'high',
          remediation: 'Compléter les informations KYC requises'
        },
        {
          id: 'fin_transaction_limits',
          description: 'Vérification des limites de transaction',
          check: ->(document, content) { RegulatoryComplianceService.check_transaction_limits(content) },
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
          id: 'env_impact',
          description: 'Évaluation de l\'impact environnemental',
          check: ->(document, content) { RegulatoryComplianceService.check_environmental_impact(content) },
          severity: 'medium',
          remediation: 'Compléter l\'évaluation environnementale'
        },
        {
          id: 'env_waste',
          description: 'Gestion des déchets',
          check: ->(document, content) { RegulatoryComplianceService.check_waste_management(content) },
          severity: 'medium',
          remediation: 'Spécifier la gestion des déchets'
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
          check: ->(document, content) { RegulatoryComplianceService.check_signatures(document, content) },
          severity: 'high',
          remediation: 'Ajouter les signatures requises'
        },
        {
          id: 'contract_clauses',
          description: 'Clauses obligatoires',
          check: ->(document, content) { RegulatoryComplianceService.check_mandatory_clauses(content) },
          severity: 'medium',
          remediation: 'Ajouter les clauses manquantes'
        }
      ]
    },
    real_estate: {
      name: 'Real Estate Compliance',
      description: 'Conformité immobilière',
      rules: [
        {
          id: 're_permits',
          description: 'Validité des permis',
          check: ->(document, content) { RegulatoryComplianceService.check_permit_validity(document, content) },
          severity: 'high',
          remediation: 'Vérifier les permis et autorisations'
        },
        {
          id: 're_safety',
          description: 'Exigences de sécurité',
          check: ->(document, content) { RegulatoryComplianceService.check_safety_requirements(content) },
          severity: 'medium',
          remediation: 'Compléter les exigences de sécurité'
        }
      ]
    }
  }.freeze
  
  def initialize(document)
    @document = document
    @violations = []
    @compliance_score = 100
    extract_document_content
  end
  
  # Method for testing purposes
  def check_category_compliance_for_tests(category)
    check_category_compliance(category, @content)
  end
end