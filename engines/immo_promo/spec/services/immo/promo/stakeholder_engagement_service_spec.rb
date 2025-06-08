require 'rails_helper'

RSpec.describe Immo::Promo::StakeholderEngagementService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#track_stakeholder_engagement' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    let!(:tasks) do
      [
        create(:immo_promo_task, phase: phase, stakeholder: stakeholder, status: 'completed'),
        create(:immo_promo_task, phase: phase, stakeholder: stakeholder, status: 'in_progress'),
        create(:immo_promo_task, phase: phase, stakeholder: stakeholder, status: 'pending')
      ]
    end
    
    let!(:contracts) do
      [
        create(:immo_promo_contract, project: project, stakeholder: stakeholder, status: 'active'),
        create(:immo_promo_contract, project: project, stakeholder: stakeholder, status: 'completed')
      ]
    end
    
    context 'for individual stakeholder' do
      it 'tracks task statistics' do
        engagement = service.track_stakeholder_engagement(stakeholder)
        
        expect(engagement[:tasks]).to include(
          total: 3,
          completed: 1,
          in_progress: 1,
          pending: 1,
          completion_rate: 33.33
        )
      end
      
      it 'tracks contract statistics' do
        engagement = service.track_stakeholder_engagement(stakeholder)
        
        expect(engagement[:contracts]).to include(
          total: 2,
          active: 1,
          completed: 1
        )
      end
      
      it 'includes engagement score' do
        engagement = service.track_stakeholder_engagement(stakeholder)
        
        expect(engagement[:engagement_score]).to be_present
      end
    end
    
    context 'for all stakeholders' do
      let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
      
      it 'tracks engagement for all stakeholders' do
        engagement = service.track_stakeholder_engagement
        
        expect(engagement).to be_a(Hash)
        expect(engagement).to have_key(stakeholder.id)
        expect(engagement).to have_key(stakeholder2.id)
      end
    end
  end
  
  describe '#identify_key_stakeholders' do
    let!(:busy_stakeholder) do
      stakeholder = create(:immo_promo_stakeholder, project: project)
      phase = create(:immo_promo_phase, project: project)
      create_list(:immo_promo_task, 5, phase: phase, stakeholder: stakeholder)
      stakeholder
    end
    
    let!(:valuable_stakeholder) do
      stakeholder = create(:immo_promo_stakeholder, project: project)
      create(:immo_promo_contract,
        project: project,
        stakeholder: stakeholder,
        amount_cents: 500_000_00
      )
      stakeholder
    end
    
    let!(:critical_stakeholder) do
      create(:immo_promo_stakeholder, project: project, is_primary: true)
    end
    
    it 'identifies stakeholders by task count' do
      key_stakeholders = service.identify_key_stakeholders
      
      expect(key_stakeholders[:by_task_count]).to include(busy_stakeholder)
    end
    
    it 'identifies stakeholders by contract value' do
      key_stakeholders = service.identify_key_stakeholders
      
      expect(key_stakeholders[:by_contract_value]).to include(valuable_stakeholder)
    end
    
    it 'identifies critical stakeholders' do
      key_stakeholders = service.identify_key_stakeholders
      
      expect(key_stakeholders[:critical]).to include(critical_stakeholder)
    end
  end
  
  describe '#generate_contact_sheet' do
    let!(:active_stakeholder) do
      create(:immo_promo_stakeholder,
        project: project,
        name: 'Active Company',
        stakeholder_type: 'contractor',
        email: 'active@example.com',
        phone: '0123456789',
        is_active: true
      )
    end
    
    let!(:inactive_stakeholder) do
      create(:immo_promo_stakeholder,
        project: project,
        name: 'Inactive Company',
        stakeholder_type: 'architect',
        status: 'inactive'
      )
    end
    
    it 'generates contact information for all stakeholders' do
      contact_sheet = service.generate_contact_sheet
      
      expect(contact_sheet).to have(2).items
    end
    
    it 'filters by active status when requested' do
      contact_sheet = service.generate_contact_sheet(active_only: true)
      
      expect(contact_sheet).to have(1).item
      expect(contact_sheet.first[:name]).to eq('Active Company')
    end
    
    it 'sorts by type and name' do
      contact_sheet = service.generate_contact_sheet
      
      expect(contact_sheet.first[:stakeholder_type]).to eq('architect')
    end
  end
  
  describe '#coordination_matrix' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    let!(:task1) do
      create(:immo_promo_task, phase: phase, stakeholder: stakeholder1)
    end
    
    let!(:task2) do
      create(:immo_promo_task,
        phase: phase,
        stakeholder: stakeholder2,
        prerequisite_tasks: [task1]
      )
    end
    
    it 'generates coordination requirements matrix' do
      matrix = service.coordination_matrix
      
      expect(matrix).to be_a(Hash)
      expect(matrix).to have_key(stakeholder1.id)
      expect(matrix).to have_key(stakeholder2.id)
      expect(matrix).to have_key(:collaboration_points)
    end
    
    it 'identifies collaboration points' do
      matrix = service.coordination_matrix
      
      collaboration_points = matrix[:collaboration_points]
      expect(collaboration_points).to be_an(Array)
      expect(collaboration_points).not_to be_empty
      
      point = collaboration_points.first
      expect(point).to include(
        :stakeholders,
        :reason,
        :phase,
        :task
      )
    end
  end
  
  describe '#analyze_performance' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, performance_rating: 'good') }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    let!(:completed_tasks) do
      [
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          status: 'completed',
          end_date: 1.week.ago,
          actual_end_date: 1.week.ago
        ),
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          status: 'completed',
          end_date: 2.weeks.ago,
          actual_end_date: 10.days.ago
        )
      ]
    end
    
    it 'calculates performance metrics' do
      performance = service.analyze_performance(stakeholder)
      
      expect(performance).to include(
        :total_tasks,
        :completed_tasks,
        :on_time_rate,
        :quality_score,
        :response_time,
        :collaboration_score,
        :overall_rating
      )
    end
    
    it 'calculates on-time delivery rate' do
      performance = service.analyze_performance(stakeholder)
      
      expect(performance[:on_time_rate]).to eq(50.0) # 1 out of 2 on time
    end
    
    it 'includes quality score based on rating' do
      performance = service.analyze_performance(stakeholder)
      
      expect(performance[:quality_score]).to eq(85) # 'good' rating
    end
  end
  
  describe '#stakeholder_overview' do
    let!(:stakeholders) do
      [
        create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect', is_active: true),
        create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor', is_active: true),
        create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor', is_active: false)
      ]
    end
    
    it 'provides stakeholder statistics' do
      overview = service.stakeholder_overview
      
      expect(overview[:total]).to eq(3)
      expect(overview[:by_type]['contractor']).to eq(2)
      expect(overview[:by_status]['active']).to eq(2)
    end
  end
  
  describe '#performance_metrics' do
    let!(:stakeholders) do
      [
        create(:immo_promo_stakeholder, project: project, performance_rating: 'excellent'),
        create(:immo_promo_stakeholder, project: project, performance_rating: 'good'),
        create(:immo_promo_stakeholder, project: project, performance_rating: 'average'),
        create(:immo_promo_stakeholder, project: project, performance_rating: 'poor')
      ]
    end
    
    it 'calculates performance distribution' do
      metrics = service.performance_metrics
      
      expect(metrics[:top_performers]).to eq(2)
      expect(metrics[:under_performers]).to eq(1)
      expect(metrics[:performance_distribution]['excellent']).to eq(1)
    end
    
    it 'calculates average performance' do
      metrics = service.performance_metrics
      
      expect(metrics[:average_performance]).to be_between(70, 80)
    end
  end
end