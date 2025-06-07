require 'rails_helper'

RSpec.describe Immo::Promo::ProjectManagerService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:service) { described_class.new(project, user) }

  describe '#initialize' do
    it 'sets project and current_user' do
      expect(service.instance_variable_get(:@project)).to eq(project)
      expect(service.instance_variable_get(:@current_user)).to eq(user)
    end
  end

  describe '#calculate_overall_progress' do
    context 'with no phases' do
      it 'returns 0' do
        expect(service.calculate_overall_progress).to eq(0)
      end
    end

    context 'with phases' do
      let!(:phase1) { create(:immo_promo_phase, project: project, phase_type: 'studies') }
      let!(:phase2) { create(:immo_promo_phase, project: project, phase_type: 'construction') }
      
      before do
        # Create completed tasks for phase1
        create_list(:immo_promo_task, 3, phase: phase1, status: 'completed')
        # Create mixed tasks for phase2 (50% completion)
        create(:immo_promo_task, phase: phase2, status: 'completed')
        create(:immo_promo_task, phase: phase2, status: 'in_progress')
      end

      it 'calculates weighted progress based on phase importance' do
        result = service.calculate_overall_progress
        expect(result).to be_a(Numeric)
        expect(result).to be > 0
        expect(result).to be <= 100
      end
    end
  end

  describe '#generate_schedule_alerts' do
    let!(:phase) { create(:immo_promo_phase, project: project, start_date: 2.weeks.ago, end_date: 1.week.ago, status: 'in_progress') }
    let!(:task) { create(:immo_promo_task, phase: phase, start_date: 1.week.ago, end_date: 2.days.ago, status: 'in_progress', priority: 'high') }
    let!(:overdue_milestone) { create(:immo_promo_milestone, phase: phase, target_date: 1.week.ago, status: 'pending') }

    it 'returns alerts for delayed items' do
      alerts = service.generate_schedule_alerts
      expect(alerts).to be_an(Array)
      expect(alerts).not_to be_empty
      
      delayed_items = alerts.select { |alert| alert[:type] == 'danger' }
      expect(delayed_items).not_to be_empty
    end
  end

  describe '#calculate_critical_path' do
    let!(:phase1) { create(:immo_promo_phase, project: project, position: 1, start_date: Date.current, end_date: Date.current + 30.days) }
    let!(:phase2) { create(:immo_promo_phase, project: project, position: 2, start_date: Date.current + 30.days, end_date: Date.current + 60.days) }
    let!(:task1) { create(:immo_promo_task, phase: phase1, estimated_hours: 40) }
    let!(:task2) { create(:immo_promo_task, phase: phase2, estimated_hours: 80) }

    it 'identifies critical path items' do
      critical_path = service.calculate_critical_path
      expect(critical_path).to be_an(Array)
      expect(critical_path).not_to be_empty
    end
  end

  describe '#optimize_resource_allocation' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:task1) { create(:immo_promo_task, phase: phase, stakeholder: stakeholder, estimated_hours: 20) }
    let!(:task2) { create(:immo_promo_task, phase: phase, stakeholder: stakeholder, estimated_hours: 30) }

    it 'provides resource optimization recommendations' do
      optimization = service.optimize_resource_allocation
      expect(optimization).to be_a(Hash)
      expect(optimization).to have_key(:recommendations)
      expect(optimization[:recommendations]).to be_an(Array)
    end
  end

  describe '#generate_progress_report' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:task) { create(:immo_promo_task, phase: phase) }
    
    before do
      # Create some completed tasks to give the phase progress
      create_list(:immo_promo_task, 3, phase: phase, status: 'completed')
      create_list(:immo_promo_task, 1, phase: phase, status: 'in_progress')
    end

    it 'generates comprehensive progress report' do
      report = service.generate_progress_report
      expect(report).to be_a(Hash)
      expect(report).to have_key(:overall_progress)
      expect(report).to have_key(:phases_progress)
      expect(report).to have_key(:key_metrics)
      expect(report).to have_key(:alerts)
    end
  end

  describe 'private methods' do
    describe '#phase_weight' do
      it 'assigns different weights to different phase types' do
        studies_phase = create(:immo_promo_phase, project: project, phase_type: 'studies')
        construction_phase = create(:immo_promo_phase, project: project, phase_type: 'construction')
        
        studies_weight = service.send(:phase_weight, studies_phase)
        construction_weight = service.send(:phase_weight, construction_phase)
        
        expect(construction_weight).to be > studies_weight
      end
    end

    describe '#task_criticality_score' do
      let(:phase) { create(:immo_promo_phase, project: project) }
      let(:high_priority_task) { create(:immo_promo_task, phase: phase, priority: 'high', estimated_hours: 100) }
      let(:low_priority_task) { create(:immo_promo_task, phase: phase, priority: 'low', estimated_hours: 10) }

      it 'assigns higher scores to more critical tasks' do
        high_score = service.send(:task_criticality_score, high_priority_task)
        low_score = service.send(:task_criticality_score, low_priority_task)
        
        expect(high_score).to be > low_score
      end
    end

    describe '#stakeholder_workload' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let(:phase) { create(:immo_promo_phase, project: project) }

      before do
        create(:immo_promo_task, phase: phase, stakeholder: stakeholder, estimated_hours: 20, status: 'in_progress')
        create(:immo_promo_task, phase: phase, stakeholder: stakeholder, estimated_hours: 30, status: 'pending')
      end

      it 'calculates total workload for stakeholder' do
        workload = service.send(:stakeholder_workload, stakeholder)
        expect(workload).to eq(50)
      end
    end

    describe '#calculate_delays' do
      let!(:delayed_phase) { create(:immo_promo_phase, project: project, start_date: 2.weeks.ago, end_date: 1.week.ago, status: 'in_progress') }
      let!(:on_time_phase) { create(:immo_promo_phase, project: project, start_date: Date.current, end_date: 1.week.from_now, status: 'in_progress') }

      it 'identifies delayed items' do
        delays = service.send(:calculate_delays)
        expect(delays[:phases]).to include(delayed_phase)
        expect(delays[:phases]).not_to include(on_time_phase)
      end
    end
  end
end