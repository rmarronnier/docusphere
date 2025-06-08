require 'rails_helper'

RSpec.describe Immo::Promo::ProjectProgressService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }
  
  describe '#overall_progress' do
    context 'with no phases' do
      it 'returns 0' do
        expect(service.overall_progress).to eq(0)
      end
    end
    
    context 'with phases and tasks' do
      let!(:phases) do
        [
          create(:immo_promo_phase, project: project, phase_type: 'studies'),
          create(:immo_promo_phase, project: project, phase_type: 'construction')
        ]
      end
      
      let!(:tasks) do
        phases.flat_map do |phase|
          [
            create(:immo_promo_task, phase: phase, status: 'completed', estimated_hours: 20),
            create(:immo_promo_task, phase: phase, status: 'in_progress', estimated_hours: 30),
            create(:immo_promo_task, phase: phase, status: 'pending', estimated_hours: 50)
          ]
        end
      end
      
      it 'calculates task-based progress' do
        progress = service.overall_progress
        
        expect(progress).to be > 0
        expect(progress).to be < 100
      end
    end
  end
  
  describe '#phase_progress' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    context 'with mixed task statuses' do
      before do
        create_list(:immo_promo_task, 3, phase: phase, status: 'completed')
        create_list(:immo_promo_task, 2, phase: phase, status: 'in_progress')
        create_list(:immo_promo_task, 5, phase: phase, status: 'pending')
      end
      
      it 'calculates phase completion percentage' do
        progress = service.phase_progress(phase)
        
        expect(progress[:completion_percentage]).to eq(30.0) # 3 out of 10 tasks
        expect(progress[:tasks_completed]).to eq(3)
        expect(progress[:tasks_total]).to eq(10)
      end
      
      it 'includes task breakdown' do
        progress = service.phase_progress(phase)
        
        expect(progress[:tasks_by_status]).to eq({
          'completed' => 3,
          'in_progress' => 2,
          'pending' => 5
        })
      end
    end
  end
  
  describe '#detailed_progress_report' do
    let!(:phases) do
      [
        create(:immo_promo_phase, 
          project: project, 
          phase_type: 'studies',
          status: 'completed'
        ),
        create(:immo_promo_phase, 
          project: project, 
          phase_type: 'permits',
          status: 'in_progress'
        ),
        create(:immo_promo_phase, 
          project: project, 
          phase_type: 'construction',
          status: 'pending'
        )
      ]
    end
    
    before do
      phases.each_with_index do |phase, index|
        completed_count = 3 - index
        create_list(:immo_promo_task, completed_count, phase: phase, status: 'completed')
        create_list(:immo_promo_task, index + 1, phase: phase, status: 'pending')
      end
    end
    
    it 'provides comprehensive progress data' do
      report = service.detailed_progress_report
      
      expect(report).to include(
        :overall_progress,
        :phase_based_progress,
        :phases,
        :critical_path_status,
        :milestone_status,
        :risk_impact_on_progress
      )
    end
    
    it 'includes phase details' do
      report = service.detailed_progress_report
      
      expect(report[:phases].size).to eq(3)
      phase_detail = report[:phases].first
      
      expect(phase_detail).to include(
        :name,
        :progress_percentage,
        :status,
        :is_delayed,
        :delay_days
      )
    end
  end
  
  describe '#milestone_progress' do
    let!(:phases) do
      create_list(:immo_promo_phase, 2, project: project)
    end
    
    let!(:milestones) do
      phases.map do |phase|
        create(:immo_promo_milestone,
          phase: phase,
          target_date: 1.month.from_now,
          status: 'pending'
        )
      end
    end
    
    before do
      milestones.first.update(status: 'completed', actual_date: Date.current)
    end
    
    it 'tracks milestone completion' do
      progress = service.milestone_progress
      
      expect(progress[:total]).to eq(2)
      expect(progress[:completed]).to eq(1)
      expect(progress[:completion_rate]).to eq(50.0)
    end
    
    it 'identifies overdue milestones' do
      milestones.last.update(target_date: 1.week.ago)
      
      progress = service.milestone_progress
      
      expect(progress[:overdue]).to eq(1)
    end
  end
  
  describe '#progress_trend_analysis' do
    it 'analyzes progress trends' do
      trend = service.progress_trend_analysis
      
      expect(trend).to include(
        :current_velocity,
        :average_velocity,
        :trend_direction,
        :projected_completion,
        :confidence_level
      )
    end
    
    context 'with historical progress data' do
      let!(:phase) { create(:immo_promo_phase, project: project) }
      
      before do
        # Simulate progress over time
        5.times do |i|
          create(:immo_promo_task,
            phase: phase,
            status: 'completed',
            actual_end_date: i.weeks.ago
          )
        end
      end
      
      it 'calculates velocity metrics' do
        trend = service.progress_trend_analysis
        
        expect(trend[:current_velocity]).to be >= 0
        expect(['improving', 'stable', 'declining']).to include(trend[:trend_direction])
      end
    end
  end
  
  describe '#identify_progress_blockers' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    context 'with dependency blockers' do
      let!(:prereq_task) do
        create(:immo_promo_task, phase: phase, status: 'pending')
      end
      
      let!(:blocked_task) do
        create(:immo_promo_task,
          phase: phase,
          status: 'pending'
        )
      end
      
      let!(:task_dependency) do
        create(:immo_promo_task_dependency,
          prerequisite_task: prereq_task,
          dependent_task: blocked_task
        )
      end
      
      it 'identifies task dependencies as blockers' do
        blockers = service.identify_progress_blockers
        
        dependency_blocker = blockers.find { |b| b[:type] == 'task_dependency' }
        expect(dependency_blocker).to be_present
      end
    end
    
    context 'with resource blockers' do
      let!(:unassigned_tasks) do
        create_list(:immo_promo_task, 3,
          phase: phase,
          stakeholder: nil,
          priority: 'high'
        )
      end
      
      it 'identifies unassigned tasks as blockers' do
        blockers = service.identify_progress_blockers
        
        resource_blocker = blockers.find { |b| b[:type] == 'resource_availability' }
        expect(resource_blocker).to be_present
      end
    end
    
    context 'with permit blockers' do
      before do
        # Set project to construction status without approved permit
        project.update(status: 'construction')
        # Ensure project cannot start construction
        allow(project).to receive(:can_start_construction?).and_return(false)
      end
      
      it 'identifies missing permits as blockers' do
        blockers = service.identify_progress_blockers
        
        permit_blocker = blockers.find { |b| b[:type] == 'permit_approval' }
        expect(permit_blocker).to be_present
      end
    end
  end
end