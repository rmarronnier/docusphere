require 'rails_helper'

RSpec.describe RegulatoryComplianceService::FinancialCompliance do
  let(:organization) { create(:organization) }
  let(:service) { RegulatoryComplianceService.new(organization) }
  
  describe '#check_kyc_compliance' do
    let(:stakeholder) { create(:immo_promo_stakeholder, organization: organization) }
    
    context 'with complete KYC documentation' do
      before do
        stakeholder.metadata['kyc_documents'] = {
          'identity_verified' => true,
          'address_verified' => true,
          'risk_assessment' => 'low',
          'verified_date' => 1.month.ago
        }
      end
      
      it 'passes KYC compliance check' do
        result = service.check_kyc_compliance(stakeholder)
        
        expect(result[:compliant]).to be true
        expect(result[:risk_level]).to eq('low')
      end
    end
    
    context 'with missing KYC documentation' do
      it 'identifies missing requirements' do
        result = service.check_kyc_compliance(stakeholder)
        
        expect(result[:compliant]).to be false
        expect(result[:missing_documents]).to include(
          'identity_verification',
          'address_proof'
        )
      end
    end
  end
  
  describe '#check_aml_compliance' do
    let(:transaction) do
      {
        amount: 50_000_00,
        source: 'bank_transfer',
        parties: ['Company A', 'Company B'],
        date: 1.week.ago
      }
    end
    
    it 'screens transactions for AML red flags' do
      result = service.check_aml_compliance(transaction)
      
      expect(result).to include(
        :risk_score,
        :red_flags,
        :requires_review,
        :suspicious_patterns
      )
    end
    
    it 'triggers alerts for high-risk transactions' do
      transaction[:amount] = 1_000_000_00
      transaction[:source] = 'cash'
      
      result = service.check_aml_compliance(transaction)
      
      expect(result[:risk_score]).to be > 70
      expect(result[:requires_review]).to be true
      expect(result[:alert_level]).to eq('high')
    end
  end
  
  describe '#verify_financial_reporting' do
    let(:financial_data) do
      {
        revenue: 1_000_000_00,
        expenses: 800_000_00,
        assets: 5_000_000_00,
        liabilities: 2_000_000_00,
        reporting_period: 'Q1 2025'
      }
    end
    
    it 'validates financial reporting compliance' do
      result = service.verify_financial_reporting(financial_data)
      
      expect(result[:compliant]).to be true
      expect(result[:ratios][:debt_to_equity]).to be < 1
      expect(result[:ratios][:profit_margin]).to eq(20.0)
    end
    
    it 'checks for accounting standards compliance' do
      result = service.verify_financial_reporting(financial_data)
      
      expect(result[:standards_compliance]).to include(
        'IFRS' => true,
        'local_gaap' => true
      )
    end
  end
  
  describe '#monitor_transaction_patterns' do
    before do
      create_list(:immo_promo_contract, 10, 
        organization: organization,
        amount_cents: rand(10_000_00..100_000_00)
      )
    end
    
    it 'detects unusual transaction patterns' do
      patterns = service.monitor_transaction_patterns(30.days)
      
      expect(patterns).to include(
        :average_transaction_size,
        :transaction_frequency,
        :unusual_patterns,
        :risk_indicators
      )
    end
  end
  
  describe '#generate_sar' do
    let(:suspicious_activity) do
      {
        transaction_id: '12345',
        amount: 500_000_00,
        parties: ['Unknown Company Ltd'],
        red_flags: ['structuring', 'unusual_amount', 'new_counterparty']
      }
    end
    
    it 'generates Suspicious Activity Report' do
      sar = service.generate_sar(suspicious_activity)
      
      expect(sar).to include(
        :report_id,
        :filing_date,
        :suspicious_activity,
        :risk_assessment,
        :recommended_actions
      )
      
      expect(sar[:priority]).to eq('high')
    end
  end
end