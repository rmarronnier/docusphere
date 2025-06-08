require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#initialize' do
    it 'creates sub-services' do
      expect(service.capacity_service).to be_a(Immo::Promo::ResourceCapacityService)
      expect(service.optimization_service).to be_a(Immo::Promo::ResourceOptimizationService)
      expect(service.skills_service).to be_a(Immo::Promo::ResourceSkillsService)
    end
  end
  
  describe '#resource_allocation_summary' do
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
    
    it 'provides comprehensive resource allocation data' do
      summary = service.resource_allocation_summary
      
      expect(summary).to include(
        :stakeholders,
        :by_phase,
        :utilization_metrics,
        :conflicts,
        :recommendations
      )
    end
    
    it 'includes stakeholder summary by status and type' do
      summary = service.resource_allocation_summary
      
      expect(summary[:stakeholders]).to include(
        :total,
        :by_status,
        :by_type,
        :overloaded,
        :available
      )
    end
    
    it 'includes phase allocation data' do
      summary = service.resource_allocation_summary
      
      expect(summary[:by_phase]).to be_an(Array)
      phase_data = summary[:by_phase].first
      expect(phase_data).to include(
        :phase,
        :status,
        :resource_count,
        :total_hours,
        :workload_distribution
      )
    end
  end
  
  describe '#stakeholder_workload_analysis' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    let!(:completed_tasks) do
      create_list(:immo_promo_task, 3,
        phase: phase,
        stakeholder: stakeholder,
        status: 'completed',
        estimated_hours: 10,
        actual_hours: 12
      )
    end
    
    let!(:active_tasks) do
      create_list(:immo_promo_task, 2,
        phase: phase,
        stakeholder: stakeholder,
        status: 'in_progress',
        estimated_hours: 20
      )
    end
    
    it 'analyzes workload for each stakeholder' do
      analysis = service.stakeholder_workload_analysis
      
      expect(analysis).to be_an(Array)
      stakeholder_data = analysis.first
      
      expect(stakeholder_data).to include(
        :stakeholder,
        :workload,
        :tasks,
        :availability,
        :efficiency_metrics
      )
    end
    
    it 'calculates workload metrics correctly' do
      analysis = service.stakeholder_workload_analysis
      workload = analysis.first[:workload]
      
      expect(workload[:active_tasks]).to eq(2)
      expect(workload[:completed_tasks]).to eq(3)
      expect(workload[:total_hours_allocated]).to eq(40)
    end
    
    it 'groups tasks by status' do
      analysis = service.stakeholder_workload_analysis
      tasks = analysis.first[:tasks]
      
      expect(tasks['completed'][:count]).to eq(3)
      expect(tasks['in_progress'][:count]).to eq(2)
    end
  end
  
  describe '#optimize_task_assignments' do
    it 'delegates to optimization service' do
      expect(service.optimization_service).to receive(:optimize_assignments)
      service.optimize_task_assignments
    end
  end
  
  describe '#resource_capacity_planning' do
    it 'delegates to capacity service' do
      expect(service.capacity_service).to receive(:analyze_capacity)
      service.resource_capacity_planning
    end
  end
  
  describe '#skill_matrix_analysis' do
    it 'delegates to skills service' do
      expect(service.skills_service).to receive(:analyze_skills_matrix)
      service.skill_matrix_analysis
    end
  end
  
  describe '#resource_conflict_calendar' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    before do
      # Create overlapping tasks
      create(:immo_promo_task,
        phase: phase,
        stakeholder: stakeholder,
        start_date: Date.current,
        end_date: Date.current + 5.days,
        status: 'in_progress'
      )
      
      create(:immo_promo_task,
        phase: phase,
        stakeholder: stakeholder,
        start_date: Date.current + 3.days,
        end_date: Date.current + 7.days,
        status: 'pending'
      )
    end
    
    it 'identifies scheduling conflicts' do
      calendar = service.resource_conflict_calendar
      
      expect(calendar).to include(
        :total_conflicts,
        :affected_resources,
        :conflicts_by_resource,
        :resolution_suggestions
      )
      
      expect(calendar[:total_conflicts]).to be > 0
      expect(calendar[:affected_resources]).to eq(1)
    end
    
    it 'provides resolution suggestions' do
      calendar = service.resource_conflict_calendar
      
      expect(calendar[:resolution_suggestions]).to be_an(Array)
      expect(calendar[:resolution_suggestions]).not_to be_empty
    end
  end
  
  describe '#calculate_utilization_metrics' do
    let!(:stakeholders) do
      [
        create(:immo_promo_stakeholder, project: project),
        create(:immo_promo_stakeholder, project: project),
        create(:immo_promo_stakeholder, project: project)
      ]
    end
    
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    before do
      # Create varied task loads
      create_list(:immo_promo_task, 5,
        phase: phase,
        stakeholder: stakeholders[0],
        estimated_hours: 30,
        status: 'in_progress'
      )
      
      create_list(:immo_promo_task, 2,
        phase: phase,
        stakeholder: stakeholders[1],
        estimated_hours: 20,
        status: 'pending'
      )
      
      # Third stakeholder has no tasks
    end
    
    it 'calculates utilization statistics' do
      summary = service.resource_allocation_summary
      metrics = summary[:utilization_metrics]
      
      expect(metrics).to include(
        :average_utilization,
        :min_utilization,
        :max_utilization,
        :standard_deviation,
        :efficiency_index
      )
      
      expect(metrics[:min_utilization]).to eq(0)
      expect(metrics[:max_utilization]).to be > 0
    end
  end
  
  describe '#identify_resource_conflicts' do
    context 'with overallocated resources' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:phase) { create(:immo_promo_phase, project: project) }
      
      before do
        # Create excessive tasks
        create_list(:immo_promo_task, 10,
          phase: phase,
          stakeholder: stakeholder,
          estimated_hours: 50,
          status: 'in_progress'
        )
      end
      
      it 'identifies overallocation conflicts' do
        summary = service.resource_allocation_summary
        conflicts = summary[:conflicts]
        
        overallocation = conflicts.find { |c| c[:type] == 'overallocation' }
        expect(overallocation).to be_present
        expect(overallocation[:severity]).to eq('high')
      end
    end
    
    context 'with skill mismatches' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:phase) { create(:immo_promo_phase, project: project) }
      let!(:task) do
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          required_skills: ['qualification']
        )
      end
      
      it 'identifies skill mismatch conflicts' do
        summary = service.resource_allocation_summary
        conflicts = summary[:conflicts]
        
        skill_mismatch = conflicts.find { |c| c[:type] == 'skill_mismatch' }
        expect(skill_mismatch).to be_present
      end
    end
  end
end