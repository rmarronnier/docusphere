require 'rails_helper'

RSpec.describe RegulatoryComplianceService::CoreOperations do
  let(:organization) { create(:organization) }
  let(:service) { RegulatoryComplianceService.new(organization) }
  
  describe '#check_compliance' do
    let(:document) { create(:document, organization: organization) }
    
    it 'returns overall compliance status' do
      result = service.check_compliance(document)
      
      expect(result).to include(
        :compliant,
        :overall_score,
        :categories,
        :issues,
        :recommendations
      )
    end
    
    it 'aggregates compliance across all categories' do
      result = service.check_compliance(document)
      
      expect(result[:categories]).to include(
        :gdpr,
        :financial,
        :environmental,
        :contractual,
        :real_estate
      )
    end
    
    it 'calculates weighted compliance score' do
      result = service.check_compliance(document)
      
      expect(result[:overall_score]).to be_between(0, 100)
    end
  end
  
  describe '#compliance_dashboard_data' do
    before do
      create_list(:document, 5, organization: organization)
    end
    
    it 'returns dashboard metrics' do
      data = service.compliance_dashboard_data
      
      expect(data).to include(
        :total_documents,
        :compliant_documents,
        :pending_reviews,
        :compliance_trends,
        :risk_areas
      )
    end
  end
  
  describe '#generate_compliance_certificate' do
    let(:document) { create(:document, organization: organization) }
    
    it 'generates certificate for compliant documents' do
      allow(service).to receive(:check_compliance).and_return({
        compliant: true,
        overall_score: 95
      })
      
      certificate = service.generate_compliance_certificate(document)
      
      expect(certificate).to include(
        :certificate_number,
        :issued_date,
        :expiry_date,
        :compliance_score,
        :verified_by
      )
    end
    
    it 'refuses certificate for non-compliant documents' do
      allow(service).to receive(:check_compliance).and_return({
        compliant: false,
        overall_score: 45
      })
      
      expect {
        service.generate_compliance_certificate(document)
      }.to raise_error(RegulatoryComplianceService::NonCompliantError)
    end
  end
  
  describe '#schedule_compliance_review' do
    let(:document) { create(:document, organization: organization) }
    
    it 'schedules periodic compliance reviews' do
      review = service.schedule_compliance_review(document, frequency: :quarterly)
      
      expect(review[:next_review_date]).to eq(3.months.from_now.to_date)
      expect(review[:frequency]).to eq(:quarterly)
    end
  end
  
  describe '#compliance_audit_trail' do
    let(:document) { create(:document, organization: organization) }
    
    it 'maintains audit trail of compliance checks' do
      service.check_compliance(document)
      service.check_compliance(document)
      
      audit_trail = service.compliance_audit_trail(document)
      
      expect(audit_trail.count).to eq(2)
      expect(audit_trail.first).to include(
        :timestamp,
        :compliance_score,
        :issues_found,
        :reviewed_by
      )
    end
  end
end