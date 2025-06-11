require 'rails_helper'

RSpec.describe Immo::Promo::Concerns::TaskCoordinator do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Immo::Promo::Concerns::TaskCoordinator
      attr_reader :project
      
      def initialize(project)
        @project = project
      end
    end
  end
  
  let(:service) { test_class.new(project) }
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  describe '#suggest_stakeholder_for_task' do
    let(:phase) { create(:immo_promo_phase, project: project) }
    let(:task) { create(:immo_promo_task, phase: phase, task_type: 'execution') }
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor') }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor') }
    
    before do
      allow(stakeholder1).to receive(:workload_status).and_return(:available)
      allow(stakeholder2).to receive(:workload_status).and_return(:overloaded)
      allow(stakeholder1).to receive(:performance_rating).and_return(:excellent)
      allow(stakeholder2).to receive(:performance_rating).and_return(:good)
      allow(stakeholder1).to receive(:can_work_on_project?).and_return(true)
      allow(stakeholder2).to receive(:can_work_on_project?).and_return(true)
      allow(stakeholder1).to receive(:has_conflicting_tasks?).and_return(false)
      allow(stakeholder2).to receive(:has_conflicting_tasks?).and_return(false)
    end
    
    it 'selects the stakeholder with best availability and performance' do
      allow(project.stakeholders).to receive_message_chain(:active, :by_type).and_return([stakeholder1, stakeholder2])
      
      result = service.suggest_stakeholder_for_task(task)
      expect(result).to eq(stakeholder1)
    end
    
    it 'returns nil when no eligible stakeholders' do
      allow(project.stakeholders).to receive_message_chain(:active, :by_type).and_return([])
      
      result = service.suggest_stakeholder_for_task(task)
      expect(result).to be_nil
    end
  end
  
  describe '#coordinate_interventions' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:task) { create(:immo_promo_task, phase: phase) }
    
    it 'returns coordination plan with phases and conflicts' do
      result = service.coordinate_interventions
      
      expect(result).to have_key(:phases)
      expect(result).to have_key(:conflicts)
      expect(result).to have_key(:optimization_suggestions)
      expect(result[:phases]).to be_an(Array)
    end
  end
  
  describe '#forecast_completion' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:task) { create(:immo_promo_task, phase: phase, priority: 'high', end_date: 2.months.from_now) }
    
    it 'returns forecast with confidence level and risk factors' do
      result = service.forecast_completion
      
      expect(result).to have_key(:forecast_date)
      expect(result).to have_key(:confidence_level)
      expect(result).to have_key(:critical_path)
      expect(result).to have_key(:risk_factors)
      expect(result[:risk_factors]).to include(:resource_availability, :weather_impact, :dependency_risks)
    end
  end
  
  describe 'private methods' do
    describe '#task_required_stakeholder_type' do
      it 'returns architect for planning tasks' do
        phase = build(:immo_promo_phase)
        task = build(:immo_promo_task, phase: phase, task_type: 'planning')
        type = service.send(:task_required_stakeholder_type, task)
        expect(type).to eq('architect')
      end
      
      it 'returns engineer for technical tasks' do
        phase = build(:immo_promo_phase)
        task = build(:immo_promo_task, phase: phase, task_type: 'technical')
        type = service.send(:task_required_stakeholder_type, task)
        expect(type).to eq('engineer')
      end
      
      it 'returns contractor for execution tasks' do
        phase = build(:immo_promo_phase)
        task = build(:immo_promo_task, phase: phase, task_type: 'execution')
        type = service.send(:task_required_stakeholder_type, task)
        expect(type).to eq('contractor')
      end
      
      it 'defaults to contractor for other types' do
        phase = build(:immo_promo_phase)
        task = build(:immo_promo_task, phase: phase, task_type: 'other')
        type = service.send(:task_required_stakeholder_type, task)
        expect(type).to eq('contractor')
      end
    end
    
    describe '#identify_scheduling_conflicts' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:task1) { create(:immo_promo_task, 
        stakeholder: stakeholder, 
        start_date: 1.week.from_now, 
        end_date: 2.weeks.from_now,
        status: 'pending'
      )}
      let!(:task2) { create(:immo_promo_task, 
        stakeholder: stakeholder, 
        start_date: 10.days.from_now, 
        end_date: 3.weeks.from_now,
        status: 'pending'
      )}
      
      it 'identifies overlapping tasks' do
        conflicts = service.send(:identify_scheduling_conflicts)
        
        expect(conflicts).not_to be_empty
        conflict = conflicts.first
        expect(conflict[:type]).to eq(:task_overlap)
        expect(conflict[:severity]).to eq(:high)
      end
    end
    
    describe '#tasks_overlap?' do
      it 'returns true for overlapping tasks' do
        task1 = build(:immo_promo_task, start_date: Date.today, end_date: 1.week.from_now)
        task2 = build(:immo_promo_task, start_date: 3.days.from_now, end_date: 2.weeks.from_now)
        
        expect(service.send(:tasks_overlap?, task1, task2)).to be true
      end
      
      it 'returns false for non-overlapping tasks' do
        task1 = build(:immo_promo_task, start_date: Date.today, end_date: 1.week.from_now)
        task2 = build(:immo_promo_task, start_date: 2.weeks.from_now, end_date: 3.weeks.from_now)
        
        expect(service.send(:tasks_overlap?, task1, task2)).to be false
      end
    end
    
    describe '#estimate_time_saving' do
      let(:tasks) do
        [
          build(:immo_promo_task, start_date: Date.today, end_date: 5.days.from_now),
          build(:immo_promo_task, start_date: Date.today, end_date: 3.days.from_now),
          build(:immo_promo_task, start_date: Date.today, end_date: 7.days.from_now)
        ]
      end
      
      it 'calculates time saving from parallelization' do
        saving = service.send(:estimate_time_saving, tasks)
        # Sequential: 5 + 3 + 7 = 15 days
        # Parallel: max(5, 3, 7) = 7 days
        # Saving: 15 - 7 = 8 days
        expect(saving).to eq(8)
      end
      
      it 'returns 0 for empty task list' do
        saving = service.send(:estimate_time_saving, [])
        expect(saving).to eq(0)
      end
    end
    
    describe '#calculate_forecast_confidence' do
      it 'returns low confidence for early progress' do
        allow(project).to receive(:calculate_overall_progress).and_return(10)
        confidence = service.send(:calculate_forecast_confidence)
        expect(confidence).to eq(40)
      end
      
      it 'returns high confidence for advanced progress' do
        allow(project).to receive(:calculate_overall_progress).and_return(85)
        confidence = service.send(:calculate_forecast_confidence)
        expect(confidence).to eq(90)
      end
    end
    
    describe '#assess_resource_risk' do
      it 'returns low risk when no overloaded stakeholders' do
        allow(project.stakeholders).to receive_message_chain(:overloaded, :count).and_return(0)
        risk = service.send(:assess_resource_risk)
        expect(risk).to eq('low')
      end
      
      it 'returns high risk when many overloaded stakeholders' do
        allow(project.stakeholders).to receive_message_chain(:overloaded, :count).and_return(4)
        risk = service.send(:assess_resource_risk)
        expect(risk).to eq('high')
      end
    end
  end
end