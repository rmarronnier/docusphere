require 'rails_helper'

RSpec.describe Immo::Promo::ResourceCapacityService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#analyze_capacity' do
    let!(:stakeholders) do
      [
        create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect'),
        create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor'),
        create(:immo_promo_stakeholder, project: project, stakeholder_type: 'engineer')
      ]
    end
    
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:tasks) do
      stakeholders.map do |stakeholder|
        create(:immo_promo_task, 
          phase: phase,
          stakeholder: stakeholder,
          estimated_hours: 20,
          status: 'in_progress'
        )
      end
    end
    
    it 'calculates current capacity' do
      result = service.analyze_capacity
      
      expect(result[:current_capacity]).to include(
        :total_available,
        :allocated,
        :available,
        :utilization_rate,
        :by_role
      )
    end
    
    it 'calculates required capacity' do
      result = service.analyze_capacity
      
      expect(result[:required_capacity]).to include(
        :total_hours_needed,
        :weeks_remaining,
        :average_hours_per_week,
        :by_phase,
        :critical_path_requirements
      )
    end
    
    it 'identifies capacity gaps' do
      result = service.analyze_capacity
      
      expect(result[:capacity_gap]).to include(
        :weekly_gap,
        :total_gap,
        :severity,
        :shortage_percentage
      )
    end
    
    it 'identifies peak resource periods' do
      result = service.analyze_capacity
      
      expect(result[:peak_periods]).to be_an(Array)
    end
    
    it 'provides recommendations' do
      result = service.analyze_capacity
      
      expect(result[:recommendations]).to be_an(Array)
    end
  end
  
  describe '#calculate_current_capacity' do
    context 'with active stakeholders' do
      let!(:stakeholders) do
        create_list(:immo_promo_stakeholder, 3, project: project, is_active: true)
      end
      
      it 'calculates total available hours' do
        capacity = service.calculate_current_capacity
        
        expect(capacity[:total_available]).to eq(120) # 3 stakeholders * 40 hours
      end
      
      it 'includes capacity by role' do
        capacity = service.calculate_current_capacity
        
        expect(capacity[:by_role]).to be_a(Hash)
      end
    end
  end
  
  describe '#identify_peak_resource_periods' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    before do
      # Create tasks with overlapping dates
      create(:immo_promo_task,
        phase: phase,
        start_date: Date.current,
        end_date: Date.current + 5.days,
        estimated_hours: 40
      )
      
      create(:immo_promo_task,
        phase: phase,
        start_date: Date.current + 2.days,
        end_date: Date.current + 7.days,
        estimated_hours: 60
      )
    end
    
    it 'identifies weeks with high demand' do
      peaks = service.identify_peak_resource_periods
      
      expect(peaks).to be_an(Array)
      expect(peaks.first).to include(:week, :demand, :tasks_count)
    end
  end
  
  describe '#capacity_recommendations' do
    context 'with resource shortage' do
      let!(:phase) { create(:immo_promo_phase, project: project) }
      
      before do
        # Create many tasks to simulate shortage
        create_list(:immo_promo_task, 10, 
          phase: phase,
          estimated_hours: 100,
          status: 'pending'
        )
      end
      
      it 'recommends adding resources' do
        recommendations = service.capacity_recommendations
        
        shortage_rec = recommendations.find { |r| r[:type] == 'resource_shortage' }
        expect(shortage_rec).to be_present
        expect(shortage_rec[:priority]).to eq('high')
      end
    end
  end
end