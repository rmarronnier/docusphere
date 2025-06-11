require 'rails_helper'

RSpec.describe RegulatoryComplianceService::GdprCompliance do
  let(:organization) { create(:organization) }
  let(:service) { RegulatoryComplianceService.new(organization) }
  
  describe '#check_gdpr_compliance' do
    let(:document) { create(:document, organization: organization) }
    
    context 'with personal data' do
      before do
        document.metadata.merge!(
          'contains_personal_data' => true,
          'data_categories' => ['name', 'email', 'phone'],
          'retention_period' => '2 years'
        )
      end
      
      it 'identifies GDPR requirements' do
        result = service.check_gdpr_compliance(document)
        
        expect(result[:compliant]).to be false
        expect(result[:issues]).to include(
          match(/consent mechanism/),
          match(/data processing agreement/)
        )
      end
      
      it 'checks for consent records' do
        document.metadata['gdpr_consent_obtained'] = true
        document.metadata['gdpr_consent_date'] = 1.month.ago.to_s
        
        result = service.check_gdpr_compliance(document)
        
        expect(result[:compliant]).to be true
        expect(result[:consent_valid]).to be true
      end
    end
    
    context 'without personal data' do
      before do
        document.metadata['contains_personal_data'] = false
      end
      
      it 'passes compliance check' do
        result = service.check_gdpr_compliance(document)
        
        expect(result[:compliant]).to be true
        expect(result[:issues]).to be_empty
      end
    end
  end
  
  describe '#audit_personal_data' do
    before do
      create_list(:document, 3, organization: organization, 
        metadata: { 'contains_personal_data' => true })
      create_list(:document, 2, organization: organization,
        metadata: { 'contains_personal_data' => false })
    end
    
    it 'returns personal data inventory' do
      audit = service.audit_personal_data
      
      expect(audit[:total_documents_with_personal_data]).to eq(3)
      expect(audit[:data_categories]).to be_an(Array)
      expect(audit[:retention_compliance]).to be_a(Hash)
    end
    
    it 'identifies retention policy violations' do
      old_document = create(:document, 
        organization: organization,
        created_at: 3.years.ago,
        metadata: { 
          'contains_personal_data' => true,
          'retention_period' => '2 years'
        }
      )
      
      audit = service.audit_personal_data
      
      expect(audit[:retention_violations]).to include(old_document.id)
    end
  end
  
  describe '#handle_data_request' do
    let(:user) { create(:user, organization: organization) }
    
    context 'access request' do
      it 'compiles user data for access request' do
        create_list(:document, 5, uploaded_by: user, organization: organization)
        create_list(:document_version, 3, whodunnit: user.id.to_s)
        
        result = service.handle_data_request(user, :access)
        
        expect(result[:status]).to eq(:completed)
        expect(result[:data][:documents_uploaded]).to eq(5)
        expect(result[:data][:versions_created]).to eq(3)
        expect(result[:export_path]).to be_present
      end
    end
    
    context 'deletion request' do
      it 'anonymizes user data' do
        document = create(:document, uploaded_by: user, organization: organization)
        
        result = service.handle_data_request(user, :deletion)
        
        expect(result[:status]).to eq(:completed)
        expect(result[:anonymized_records]).to be > 0
        
        document.reload
        expect(document.uploaded_by).to be_nil
        expect(document.metadata['uploaded_by_name']).to eq('[ANONYMIZED]')
      end
      
      it 'maintains data integrity while anonymizing' do
        document = create(:document, organization: organization)
        version = document.versions.create!(whodunnit: user.id.to_s)
        
        service.handle_data_request(user, :deletion)
        
        version.reload
        expect(version.whodunnit).to eq('anonymized')
      end
    end
    
    context 'portability request' do
      it 'exports data in machine-readable format' do
        result = service.handle_data_request(user, :portability)
        
        expect(result[:status]).to eq(:completed)
        expect(result[:format]).to eq('json')
        expect(File.exist?(result[:export_path])).to be true
        
        exported_data = JSON.parse(File.read(result[:export_path]))
        expect(exported_data).to have_key('user_profile')
        expect(exported_data).to have_key('documents')
        expect(exported_data).to have_key('activities')
      end
    end
  end
  
  describe '#check_consent_validity' do
    let(:consent_record) do
      {
        granted_at: 1.year.ago,
        purpose: 'document_storage',
        expires_at: 1.year.from_now
      }
    end
    
    it 'validates consent is current' do
      result = service.check_consent_validity(consent_record)
      
      expect(result[:valid]).to be true
      expect(result[:days_until_expiry]).to be > 0
    end
    
    it 'identifies expired consent' do
      consent_record[:expires_at] = 1.day.ago
      
      result = service.check_consent_validity(consent_record)
      
      expect(result[:valid]).to be false
      expect(result[:renewal_required]).to be true
    end
  end
  
  describe '#generate_privacy_report' do
    it 'creates comprehensive privacy report' do
      report = service.generate_privacy_report
      
      expect(report).to include(
        :data_inventory,
        :consent_summary,
        :retention_compliance,
        :access_logs,
        :third_party_sharing,
        :security_measures
      )
    end
    
    it 'includes recommendations' do
      report = service.generate_privacy_report
      
      expect(report[:recommendations]).to be_an(Array)
      expect(report[:compliance_score]).to be_between(0, 100)
    end
  end
end