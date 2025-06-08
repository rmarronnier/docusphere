require 'rails_helper'

RSpec.describe Immo::Promo::ResourceOptimizationService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#optimize_assignments' do
    let!(:overloaded_stakeholder) do
      create(:immo_promo_stakeholder, project: project, performance_rating: 'good')
    end
    
    let!(:available_stakeholder) do
      create(:immo_promo_stakeholder, project: project, performance_rating: 'excellent')
    end
    
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    before do
      # Create many tasks for overloaded stakeholder
      5.times do
        create(:immo_promo_task,
          phase: phase,
          stakeholder: overloaded_stakeholder,
          estimated_hours: 30,
          status: 'pending',
          start_date: 2.weeks.from_now
        )
      end
      
      # Create one task for available stakeholder
      create(:immo_promo_task,
        phase: phase,
        stakeholder: available_stakeholder,
        estimated_hours: 10,
        status: 'pending'
      )
    end
    
    it 'generates reassignment recommendations' do
      result = service.optimize_assignments
      
      expect(result[:reassignments]).to be_an(Array)
      expect(result[:reassignments]).not_to be_empty
    end
    
    it 'assigns unassigned tasks' do
      # Create unassigned task
      create(:immo_promo_task, phase: phase, stakeholder: nil, estimated_hours: 20)
      
      result = service.optimize_assignments
      
      expect(result[:new_assignments]).to be_an(Array)
      expect(result[:new_assignments]).not_to be_empty
    end
    
    it 'provides load balancing analysis' do
      result = service.optimize_assignments
      
      expect(result[:load_balancing]).to include(
        :current_balance,
        :imbalances,
        :recommendations
      )
    end
    
    it 'identifies efficiency improvements' do
      result = service.optimize_assignments
      
      expect(result[:efficiency_improvements]).to be_an(Array)
    end
  end
  
  describe '#find_best_assignee_for_task' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let(:task) { create(:immo_promo_task, phase: phase, stakeholder: nil) }
    
    let!(:qualified_stakeholder) do
      stakeholder = create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect')
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'architect_license',
        is_valid: true
      )
      stakeholder
    end
    
    let!(:busy_stakeholder) do
      stakeholder = create(:immo_promo_stakeholder, project: project)
      5.times do
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          status: 'in_progress',
          estimated_hours: 40
        )
      end
      stakeholder
    end
    
    context 'with available qualified stakeholder' do
      it 'selects the best candidate' do
        assignee = service.find_best_assignee_for_task(task)
        
        expect(assignee).to eq(qualified_stakeholder)
      end
    end
    
    context 'with skill requirements' do
      before do
        task.update(required_skills: ['architect_license'])
      end
      
      it 'only considers stakeholders with required skills' do
        assignee = service.find_best_assignee_for_task(task)
        
        expect(assignee).to eq(qualified_stakeholder)
      end
    end
  end
  
  describe '#balance_workload' do
    let!(:stakeholders) do
      create_list(:immo_promo_stakeholder, 4, project: project)
    end
    
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    before do
      # Create uneven task distribution
      create_list(:immo_promo_task, 5,
        phase: phase,
        stakeholder: stakeholders.first,
        estimated_hours: 30,
        status: 'pending'
      )
      
      create(:immo_promo_task,
        phase: phase,
        stakeholder: stakeholders.last,
        estimated_hours: 10,
        status: 'pending'
      )
    end
    
    it 'identifies workload imbalances' do
      result = service.balance_workload
      
      expect(result[:imbalances]).not_to be_empty
      expect(result[:recommendations]).to be_an(Array)
    end
    
    it 'calculates workload statistics' do
      result = service.balance_workload
      
      expect(result[:current_balance]).to include(
        :average,
        :standard_deviation,
        :min,
        :max,
        :range
      )
    end
  end
  
  describe '#identify_efficiency_improvements' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    
    context 'with skill mismatches' do
      let!(:task) do
        create(:immo_promo_task,
          phase: phase,
          stakeholder: stakeholder,
          required_skills: ['architect_license', 'project_management']
        )
      end
      
      it 'identifies tasks assigned to unqualified resources' do
        improvements = service.identify_efficiency_improvements
        
        skill_mismatch = improvements.find { |i| i[:type] == 'skill_mismatch' }
        expect(skill_mismatch).to be_present
      end
    end
    
    context 'with task grouping opportunities' do
      before do
        # Create multiple tasks for same stakeholder in same phase
        3.times do |i|
          create(:immo_promo_task,
            phase: phase,
            stakeholder: stakeholder,
            status: 'pending',
            start_date: Date.current + i.days,
            end_date: Date.current + (i + 1).days,
            estimated_hours: 10
          )
        end
      end
      
      it 'identifies groupable tasks' do
        improvements = service.identify_efficiency_improvements
        
        grouping = improvements.find { |i| i[:type] == 'task_grouping' }
        expect(grouping).to be_present
      end
    end
    
    context 'with underutilized resources' do
      let!(:underutilized) do
        create(:immo_promo_stakeholder, project: project)
      end
      
      it 'identifies underutilized stakeholders' do
        improvements = service.identify_efficiency_improvements
        
        underutilization = improvements.find { |i| i[:type] == 'underutilization' }
        expect(underutilization).to be_present
      end
    end
  end
end