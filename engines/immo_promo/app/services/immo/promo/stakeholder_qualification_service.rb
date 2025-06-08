module Immo
  module Promo
    class StakeholderQualificationService
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def check_all_qualifications
        qualification_issues = []
        
        project.stakeholders.active.each do |stakeholder|
          issues = check_stakeholder_qualifications(stakeholder)
          qualification_issues.concat(issues) if issues.any?
        end
        
        {
          issues: qualification_issues,
          compliance_rate: calculate_compliance_rate,
          summary: generate_qualification_summary
        }
      end

      def check_stakeholder_qualifications(stakeholder)
        stakeholder.qualification_issues.map do |issue|
          build_qualification_issue(stakeholder, issue)
        end
      end

      def check_contract_compliance
        compliance_data = {
          expired_contracts: [],
          expiring_soon: [],
          total: 0,
          compliant: [],
          compliance_rate: 0
        }
        
        active_contracts = project.contracts.where(status: 'active')
        compliance_data[:total] = active_contracts.count
        
        active_contracts.each do |contract|
          if contract.is_expired?
            compliance_data[:expired_contracts] << contract
          elsif contract.days_until_expiry && contract.days_until_expiry <= 30
            compliance_data[:expiring_soon] << contract
          else
            compliance_data[:compliant] << contract
          end
        end
        
        if compliance_data[:total] > 0
          compliance_rate = compliance_data[:compliant].count.to_f / compliance_data[:total] * 100
          compliance_data[:compliance_rate] = compliance_rate.round(2)
        end
        
        compliance_data
      end

      def validate_team_competencies(phase)
        missing_competencies = []
        required_types = required_stakeholder_types_for(phase.phase_type)
        
        required_types.each do |required_type|
          stakeholders = project.stakeholders.active.by_type(required_type)
          
          if stakeholders.empty?
            missing_competencies << {
              type: required_type,
              message: "Aucun #{required_type.humanize} actif dans le projet"
            }
            next
          end
          
          # Vérifier les qualifications spécifiques
          stakeholders.each do |stakeholder|
            issues = stakeholder.qualification_issues
            if issues.any?
              missing_competencies << {
                stakeholder: stakeholder,
                issues: issues,
                message: format_qualification_issues(stakeholder, issues)
              }
            end
          end
        end
        
        missing_competencies
      end
      
      def coordination_risks
        risks = []
        
        # Qualification risks
        qualification_issues = check_all_qualifications[:issues]
        if qualification_issues.any? { |i| i[:severity] == :critical }
          risks << {
            type: 'qualification',
            severity: 'high',
            description: 'Critical qualification issues found',
            count: qualification_issues.count { |i| i[:severity] == :critical }
          }
        end
        
        # Contract risks
        contract_compliance = check_contract_compliance
        if contract_compliance[:expired_contracts].any?
          risks << {
            type: 'contract',
            severity: 'high',
            description: 'Expired contracts detected',
            count: contract_compliance[:expired_contracts].count
          }
        end
        
        risks
      end
      
      def risk_recommendations
        recommendations = []
        
        qualification_issues = check_all_qualifications[:issues]
        qualification_issues.each do |issue|
          recommendations << {
            type: 'qualification',
            priority: issue[:severity],
            action: issue[:action_required],
            stakeholder: issue[:stakeholder]
          }
        end
        
        recommendations
      end
      
      def missing_certifications_for(stakeholder)
        required_certs = required_certifications_for_type(stakeholder.stakeholder_type)
        existing_certs = stakeholder.certifications.pluck(:certification_type)
        
        required_certs - existing_certs
      end
      
      def stakeholder_status(stakeholder)
        if stakeholder.qualification_issues.empty?
          'compliant'
        elsif stakeholder.qualification_issues.any? { |i| severity_for(i) == :critical }
          'critical'
        else
          'warning'
        end
      end

      private

      def build_qualification_issue(stakeholder, issue_type)
        {
          stakeholder: stakeholder,
          type: issue_type,
          severity: severity_for(issue_type),
          message: message_for(stakeholder, issue_type),
          action_required: action_for(issue_type),
          impact: impact_for(issue_type)
        }
      end

      def severity_for(issue_type)
        case issue_type
        when :insurance_missing
          :critical
        when :qualification_missing
          :high
        when :registration_missing
          :medium
        else
          :low
        end
      end

      def message_for(stakeholder, issue_type)
        case issue_type
        when :insurance_missing
          "#{stakeholder.name} : Assurance professionnelle manquante ou expirée"
        when :qualification_missing
          "#{stakeholder.name} : Qualification professionnelle non vérifiée"
        when :registration_missing
          "#{stakeholder.name} : Inscription à l'Ordre des Architectes requise"
        else
          "#{stakeholder.name} : Problème de qualification"
        end
      end

      def action_for(issue_type)
        case issue_type
        when :insurance_missing
          "Demander attestation d'assurance en cours de validité"
        when :qualification_missing
          "Vérifier les certifications professionnelles"
        when :registration_missing
          "Confirmer l'inscription à l'Ordre professionnel"
        else
          "Vérifier les documents"
        end
      end

      def impact_for(issue_type)
        case issue_type
        when :insurance_missing
          "Risque juridique élevé - Ne peut pas intervenir sur le chantier"
        when :qualification_missing
          "Peut retarder certaines phases nécessitant des qualifications spécifiques"
        when :registration_missing
          "Ne peut pas signer certains documents officiels"
        else
          "Impact à évaluer"
        end
      end

      def calculate_compliance_rate
        total = project.stakeholders.active.count
        return 100 if total.zero?
        
        compliant = project.stakeholders.active.select { |s| s.qualification_issues.empty? }.count
        (compliant.to_f / total * 100).round(2)
      end

      def generate_qualification_summary
        {
          total_stakeholders: project.stakeholders.active.count,
          fully_qualified: project.stakeholders.active.select { |s| s.qualification_issues.empty? }.count,
          missing_insurance: count_issue_type(:insurance_missing),
          missing_qualification: count_issue_type(:qualification_missing),
          missing_registration: count_issue_type(:registration_missing)
        }
      end

      def count_issue_type(issue_type)
        project.stakeholders.active.select { |s| s.qualification_issues.include?(issue_type) }.count
      end

      def required_stakeholder_types_for(phase_type)
        case phase_type.to_s
        when 'studies'
          ['architect', 'engineer']
        when 'permits'
          ['architect']
        when 'construction'
          ['architect', 'engineer', 'contractor', 'control_office']
        when 'reception'
          ['architect', 'control_office']
        else
          []
        end
      end

      def format_qualification_issues(stakeholder, issues)
        issue_messages = issues.map { |issue| message_for(stakeholder, issue) }
        issue_messages.join(", ")
      end
      
      def required_certifications_for_type(stakeholder_type)
        case stakeholder_type
        when 'architect'
          ['architect_license', 'professional_insurance']
        when 'engineer'
          ['engineering_certification', 'professional_insurance']
        when 'contractor'
          ['construction_license', 'safety_certification', 'professional_insurance']
        when 'control_office'
          ['control_certification', 'professional_insurance']
        else
          ['professional_insurance']
        end
      end
    end
  end
end