require 'rails_helper'

RSpec.describe RegulatoryComplianceService::ContractualCompliance do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { RegulatoryComplianceService.new(organization) }
  
  describe '#check_contract_compliance' do
    let(:contract) { create(:immo_promo_contract, project: project) }
    
    context 'with valid contract' do
      before do
        contract.update!(
          start_date: 1.month.ago,
          end_date: 1.year.from_now,
          status: 'active',
          signed_at: 1.month.ago
        )
      end
      
      it 'passes compliance check' do
        result = service.check_contract_compliance(contract)
        
        expect(result[:compliant]).to be true
        expect(result[:issues]).to be_empty
      end
    end
    
    context 'with compliance issues' do
      it 'identifies missing signatures' do
        contract.update!(signed_at: nil)
        
        result = service.check_contract_compliance(contract)
        
        expect(result[:compliant]).to be false
        expect(result[:issues]).to include(match(/signature required/))
      end
      
      it 'identifies expired contracts' do
        contract.update!(end_date: 1.day.ago)
        
        result = service.check_contract_compliance(contract)
        
        expect(result[:issues]).to include(match(/contract expired/))
      end
    end
  end
  
  describe '#verify_contract_terms' do
    let(:contract) { create(:immo_promo_contract, project: project) }
    
    it 'validates required clauses are present' do
      required_clauses = ['payment_terms', 'liability', 'termination']
      contract.metadata['clauses'] = ['payment_terms', 'liability']
      
      result = service.verify_contract_terms(contract, required_clauses)
      
      expect(result[:missing_clauses]).to include('termination')
      expect(result[:compliant]).to be false
    end
  end
  
  describe '#check_sla_compliance' do
    let(:sla_metrics) do
      {
        response_time: { target: 4, actual: 6 },
        uptime: { target: 99.9, actual: 99.5 },
        resolution_time: { target: 24, actual: 20 }
      }
    end
    
    it 'identifies SLA violations' do
      result = service.check_sla_compliance(sla_metrics)
      
      expect(result[:violations]).to include(:response_time, :uptime)
      expect(result[:violations]).not_to include(:resolution_time)
      expect(result[:compliance_rate]).to be < 100
    end
  end
  
  describe '#audit_contract_obligations' do
    it 'tracks fulfillment of contractual obligations' do
      obligations = [
        { description: 'Monthly report', due_date: 1.week.ago, completed: true },
        { description: 'Quarterly review', due_date: 1.day.ago, completed: false },
        { description: 'Annual audit', due_date: 1.month.from_now, completed: false }
      ]
      
      result = service.audit_contract_obligations(obligations)
      
      expect(result[:overdue]).to eq(1)
      expect(result[:completed]).to eq(1)
      expect(result[:upcoming]).to eq(1)
      expect(result[:compliance_status]).to eq('at_risk')
    end
  end
  
  describe '#generate_contract_compliance_report' do
    it 'creates comprehensive compliance report' do
      contracts = create_list(:immo_promo_contract, 3, project: project)
      
      report = service.generate_contract_compliance_report(project)
      
      expect(report).to include(
        :total_contracts,
        :compliant_contracts,
        :non_compliant_contracts,
        :expiring_soon,
        :compliance_percentage
      )
    end
  end
end