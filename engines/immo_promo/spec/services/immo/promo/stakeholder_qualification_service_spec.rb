require 'rails_helper'

RSpec.describe Immo::Promo::StakeholderQualificationService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#check_all_qualifications' do
    let!(:qualified_stakeholder) do
      stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect')
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'insurance',
        is_valid: true,
        expiry_date: 1.year.from_now
      )
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'qualification',
        is_valid: true
      )
      stakeholder
    end
    
    let!(:unqualified_stakeholder) do
      create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor')
    end
    
    it 'identifies qualification issues' do
      result = service.check_all_qualifications
      
      expect(result[:issues]).to be_an(Array)
      expect(result[:issues]).not_to be_empty
      
      issue = result[:issues].first
      expect(issue[:stakeholder]).to eq(unqualified_stakeholder)
    end
    
    it 'calculates compliance rate' do
      result = service.check_all_qualifications
      
      expect(result[:compliance_rate]).to eq(50.0) # 1 out of 2 compliant
    end
    
    it 'provides qualification summary' do
      result = service.check_all_qualifications
      
      expect(result[:summary]).to include(
        :total_stakeholders,
        :fully_qualified,
        :missing_insurance,
        :missing_qualification,
        :missing_registration
      )
    end
  end
  
  describe '#check_stakeholder_qualifications' do
    context 'with missing insurance' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      
      it 'identifies missing insurance' do
        issues = service.check_stakeholder_qualifications(stakeholder)
        
        insurance_issue = issues.find { |i| i[:type] == :insurance_missing }
        expect(insurance_issue).to be_present
        expect(insurance_issue[:severity]).to eq(:critical)
      end
    end
    
    context 'with architect missing registration' do
      let(:architect) do
        stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect')
        # Has insurance but no architect registration
        create(:immo_promo_certification,
          stakeholder: stakeholder,
          certification_type: 'insurance',
          is_valid: true
        )
        stakeholder
      end
      
      it 'identifies missing architect registration' do
        issues = service.check_stakeholder_qualifications(architect)
        
        registration_issue = issues.find { |i| i[:type] == :registration_missing }
        expect(registration_issue).to be_present
      end
    end
  end
  
  describe '#check_contract_compliance' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    
    let!(:active_contract) do
      create(:immo_promo_contract,
        project: project,
        stakeholder: stakeholder1,
        status: 'active',
        end_date: 6.months.from_now
      )
    end
    
    let!(:expired_contract) do
      create(:immo_promo_contract,
        project: project,
        stakeholder: stakeholder2,
        status: 'active',
        end_date: 1.week.ago
      )
    end
    
    let!(:expiring_contract) do
      create(:immo_promo_contract,
        project: project,
        stakeholder: stakeholder1,
        status: 'active',
        end_date: 2.weeks.from_now
      )
    end
    
    it 'identifies expired contracts' do
      compliance = service.check_contract_compliance
      
      expect(compliance[:expired_contracts]).to have(1).item
      expect(compliance[:expired_contracts].first).to eq(expired_contract)
    end
    
    it 'identifies contracts expiring soon' do
      compliance = service.check_contract_compliance
      
      expect(compliance[:expiring_soon]).to have(1).item
      expect(compliance[:expiring_soon].first).to eq(expiring_contract)
    end
    
    it 'calculates compliance rate' do
      compliance = service.check_contract_compliance
      
      expect(compliance[:compliance_rate]).to eq(33.33) # 1 out of 3 compliant
    end
  end
  
  describe '#validate_team_competencies' do
    let(:construction_phase) do
      create(:immo_promo_phase, project: project, phase_type: 'construction')
    end
    
    context 'with missing stakeholder types' do
      it 'identifies missing required stakeholder types' do
        competencies = service.validate_team_competencies(construction_phase)
        
        expect(competencies).not_to be_empty
        
        missing_types = competencies.select { |c| c[:type].present? }
        expect(missing_types.map { |c| c[:type] }).to include('architect', 'engineer', 'contractor')
      end
    end
    
    context 'with unqualified stakeholders' do
      let!(:unqualified_architect) do
        create(:immo_promo_stakeholder,
          project: project,
          stakeholder_type: 'architect'
        )
      end
      
      it 'identifies qualification issues for existing stakeholders' do
        competencies = service.validate_team_competencies(construction_phase)
        
        architect_issues = competencies.find { |c| c[:stakeholder] == unqualified_architect }
        expect(architect_issues).to be_present
        expect(architect_issues[:issues]).to include(:insurance_missing)
      end
    end
  end
  
  describe '#coordination_risks' do
    context 'with critical qualification issues' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      
      it 'identifies qualification risks' do
        risks = service.coordination_risks
        
        qualification_risk = risks.find { |r| r[:type] == 'qualification' }
        expect(qualification_risk).to be_present
        expect(qualification_risk[:severity]).to eq('high')
      end
    end
    
    context 'with expired contracts' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:expired_contract) do
        create(:immo_promo_contract,
          project: project,
          stakeholder: stakeholder,
          status: 'active',
          end_date: 1.month.ago
        )
      end
      
      it 'identifies contract risks' do
        risks = service.coordination_risks
        
        contract_risk = risks.find { |r| r[:type] == 'contract' }
        expect(contract_risk).to be_present
        expect(contract_risk[:severity]).to eq('high')
      end
    end
  end
  
  describe '#risk_recommendations' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    
    it 'provides recommendations for qualification issues' do
      recommendations = service.risk_recommendations
      
      expect(recommendations).to be_an(Array)
      expect(recommendations).not_to be_empty
      
      rec = recommendations.first
      expect(rec[:type]).to eq('qualification')
      expect(rec[:action]).to be_present
    end
  end
  
  describe '#missing_certifications_for' do
    let(:architect) do
      stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect')
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'architect_license',
        is_valid: true
      )
      stakeholder
    end
    
    it 'identifies missing required certifications' do
      missing = service.missing_certifications_for(architect)
      
      expect(missing).to include('professional_insurance')
      expect(missing).not_to include('architect_license')
    end
  end
  
  describe '#stakeholder_status' do
    context 'with compliant stakeholder' do
      let(:stakeholder) do
        s = create(:immo_promo_stakeholder, project: project)
        create(:immo_promo_certification,
          stakeholder: s,
          certification_type: 'insurance',
          is_valid: true
        )
        create(:immo_promo_certification,
          stakeholder: s,
          certification_type: 'qualification',
          is_valid: true
        )
        s
      end
      
      it 'returns compliant status' do
        status = service.stakeholder_status(stakeholder)
        expect(status).to eq('compliant')
      end
    end
    
    context 'with critical issues' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      
      it 'returns critical status' do
        status = service.stakeholder_status(stakeholder)
        expect(status).to eq('critical')
      end
    end
  end
end