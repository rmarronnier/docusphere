require 'rails_helper'

RSpec.describe RegulatoryComplianceService::RealEstateCompliance do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { RegulatoryComplianceService.new(organization) }
  
  describe '#check_zoning_compliance' do
    before do
      project.metadata['location'] = {
        'zone_type' => 'residential',
        'max_height' => 15,
        'max_coverage' => 60
      }
      project.metadata['building_specs'] = {
        'height' => 12,
        'coverage' => 55
      }
    end
    
    it 'validates project against zoning regulations' do
      result = service.check_zoning_compliance(project)
      
      expect(result[:compliant]).to be true
      expect(result[:violations]).to be_empty
    end
    
    it 'identifies zoning violations' do
      project.metadata['building_specs']['height'] = 18
      
      result = service.check_zoning_compliance(project)
      
      expect(result[:compliant]).to be false
      expect(result[:violations]).to include(match(/height exceeds maximum/))
    end
  end
  
  describe '#verify_building_permits' do
    let(:permits) do
      [
        create(:immo_promo_permit, project: project, permit_type: 'building', status: 'approved'),
        create(:immo_promo_permit, project: project, permit_type: 'demolition', status: 'pending')
      ]
    end
    
    it 'checks all required permits are obtained' do
      result = service.verify_building_permits(project, permits)
      
      expect(result[:missing_permits]).to include('occupancy_permit')
      expect(result[:pending_permits]).to include('demolition')
      expect(result[:approved_permits]).to include('building')
    end
  end
  
  describe '#check_property_title' do
    let(:title_data) do
      {
        owner: 'ABC Development Ltd',
        encumbrances: [],
        liens: [],
        easements: ['utility_access']
      }
    end
    
    it 'validates clear property title' do
      result = service.check_property_title(project, title_data)
      
      expect(result[:title_clear]).to be true
      expect(result[:issues]).to be_empty
    end
    
    it 'identifies title issues' do
      title_data[:liens] = ['tax_lien', 'mechanic_lien']
      
      result = service.check_property_title(project, title_data)
      
      expect(result[:title_clear]).to be false
      expect(result[:issues]).to include(match(/liens present/))
    end
  end
  
  describe '#verify_sales_compliance' do
    let(:sales_data) do
      {
        pre_sales_percentage: 30,
        sales_documentation: ['brochure', 'price_list'],
        escrow_account: true
      }
    end
    
    it 'validates real estate sales compliance' do
      result = service.verify_sales_compliance(project, sales_data)
      
      expect(result[:compliant]).to be true
      expect(result[:pre_sales_requirement_met]).to be true
    end
    
    it 'checks for required disclosures' do
      result = service.verify_sales_compliance(project, sales_data)
      
      expect(result[:missing_disclosures]).to include(
        'construction_timeline',
        'defect_liability_period'
      )
    end
  end
  
  describe '#check_construction_standards' do
    it 'validates compliance with building codes' do
      construction_data = {
        materials: 'approved_list',
        safety_measures: ['fire_exits', 'emergency_lighting'],
        accessibility: 'wheelchair_compliant'
      }
      
      result = service.check_construction_standards(project, construction_data)
      
      expect(result[:code_compliant]).to be true
      expect(result[:safety_compliant]).to be true
      expect(result[:accessibility_compliant]).to be true
    end
  end
  
  describe '#monitor_regulatory_changes' do
    it 'tracks changes in real estate regulations' do
      changes = service.monitor_regulatory_changes
      
      expect(changes).to include(
        :new_regulations,
        :amended_regulations,
        :upcoming_changes,
        :impact_assessment
      )
    end
  end
end