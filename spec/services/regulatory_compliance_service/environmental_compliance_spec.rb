require 'rails_helper'

RSpec.describe RegulatoryComplianceService::EnvironmentalCompliance do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { RegulatoryComplianceService.new(organization) }
  
  describe '#check_environmental_compliance' do
    context 'with construction project' do
      before do
        project.metadata['project_type'] = 'construction'
        project.metadata['location'] = 'urban'
        project.metadata['size_sqm'] = 5000
      end
      
      it 'identifies required environmental permits' do
        result = service.check_environmental_compliance(project)
        
        expect(result[:required_permits]).to include(
          'environmental_impact_assessment',
          'noise_permit',
          'waste_management_plan'
        )
      end
      
      it 'checks for environmental impact study' do
        result = service.check_environmental_compliance(project)
        
        expect(result[:compliant]).to be false
        expect(result[:missing_documents]).to include('Environmental Impact Study')
      end
    end
    
    context 'with green certifications' do
      before do
        project.metadata['certifications'] = ['BREEAM', 'LEED Gold']
      end
      
      it 'validates green building certifications' do
        result = service.check_environmental_compliance(project)
        
        expect(result[:green_certifications][:valid]).to include('BREEAM', 'LEED Gold')
        expect(result[:sustainability_score]).to be > 80
      end
    end
  end
  
  describe '#calculate_carbon_footprint' do
    let(:project_data) do
      {
        construction_area: 5000,
        materials: { concrete: 1000, steel: 200 },
        energy_consumption: { electricity: 50000, gas: 20000 }
      }
    end
    
    it 'calculates project carbon footprint' do
      result = service.calculate_carbon_footprint(project, project_data)
      
      expect(result[:total_co2_tons]).to be > 0
      expect(result[:breakdown]).to include(
        :materials,
        :energy,
        :transport,
        :waste
      )
    end
    
    it 'provides reduction recommendations' do
      result = service.calculate_carbon_footprint(project, project_data)
      
      expect(result[:recommendations]).to be_an(Array)
      expect(result[:potential_reduction_percentage]).to be > 0
    end
  end
  
  describe '#verify_waste_management' do
    let(:waste_plan) do
      {
        recycling_rate: 75,
        hazardous_waste_handling: 'certified_contractor',
        disposal_sites: ['licensed_site_1', 'licensed_site_2']
      }
    end
    
    it 'validates waste management compliance' do
      result = service.verify_waste_management(project, waste_plan)
      
      expect(result[:compliant]).to be true
      expect(result[:recycling_target_met]).to be true
    end
    
    it 'identifies non-compliance issues' do
      waste_plan[:recycling_rate] = 40
      
      result = service.verify_waste_management(project, waste_plan)
      
      expect(result[:compliant]).to be false
      expect(result[:issues]).to include(match(/recycling rate below requirement/))
    end
  end
  
  describe '#monitor_environmental_kpis' do
    it 'tracks environmental performance indicators' do
      kpis = service.monitor_environmental_kpis(project)
      
      expect(kpis).to include(
        :energy_efficiency,
        :water_conservation,
        :waste_diversion_rate,
        :biodiversity_impact,
        :air_quality_index
      )
    end
  end
  
  describe '#generate_environmental_report' do
    it 'creates comprehensive environmental compliance report' do
      report = service.generate_environmental_report(project)
      
      expect(report).to include(
        :executive_summary,
        :compliance_status,
        :environmental_impact,
        :mitigation_measures,
        :monitoring_plan,
        :certification_status
      )
    end
  end
end