require 'rails_helper'

RSpec.describe Immo::Promo::ProjectManagerService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:service) { described_class.new(project, user) }

  describe '#calculate_overall_progress' do
    context 'when no tasks exist' do
      it 'returns 0' do
        expect(service.calculate_overall_progress).to eq(0)
      end
    end

    context 'when tasks exist' do
      let(:phase) { create(:immo_promo_phase, project: project) }
      
      before do
        create_list(:immo_promo_task, 3, phase: phase, status: 'completed')
        create_list(:immo_promo_task, 2, phase: phase, status: 'in_progress')
        create_list(:immo_promo_task, 5, phase: phase, status: 'pending')
      end

      it 'calculates progress based on task completion' do
        # 3 completed out of 10 total = 30%
        expect(service.calculate_overall_progress).to eq(30)
      end
    end
  end

  describe '#generate_project_report' do
    it 'generates a comprehensive report' do
      report = service.generate_project_report

      expect(report).to include(:project_info)
      expect(report).to include(:progress)
      expect(report).to include(:financial_status)
      expect(report).to include(:schedule_status)
      expect(report).to include(:resource_status)
      expect(report).to include(:risks)
      expect(report).to include(:milestones)
    end
  end

  describe '#update_project_timeline' do
    let(:phase) { create(:immo_promo_phase, project: project) }

    it 'updates phase dates based on dependencies' do
      new_start_date = Date.current + 1.month
      service.update_project_timeline(phase, new_start_date)

      phase.reload
      expect(phase.start_date).to eq(new_start_date)
    end
  end

  describe '#assign_resources' do
    let(:phase) { create(:immo_promo_phase, project: project) }
    let(:task) { create(:immo_promo_task, phase: phase) }
    let(:new_assignee) { create(:user, organization: organization) }

    it 'assigns user to task' do
      service.assign_resources(task, new_assignee)

      task.reload
      expect(task.assigned_to).to eq(new_assignee)
    end
  end

  describe '#track_budget_usage' do
    let(:budget) { create(:immo_promo_budget, project: project) }
    
    before do
      create(:immo_promo_budget_line,
        budget: budget,
        category: 'construction_work',
        planned_amount_cents: 100_000_00,
        actual_amount_cents: 80_000_00
      )
      create(:immo_promo_budget_line,
        budget: budget,
        category: 'studies',
        planned_amount_cents: 20_000_00,
        actual_amount_cents: 25_000_00
      )
    end

    it 'calculates budget usage statistics' do
      stats = service.track_budget_usage

      expect(stats[:total_planned].cents).to eq(120_000_00)
      expect(stats[:total_actual].cents).to eq(105_000_00)
      expect(stats[:variance].cents).to eq(15_000_00)
      expect(stats[:usage_percentage]).to eq(87.5)
    end
  end

  describe '#critical_path_analysis' do
    it 'identifies critical tasks' do
      phase1 = create(:immo_promo_phase, :studies, project: project, is_critical: true)
      phase2 = create(:immo_promo_phase, :permits, project: project)

      task1 = create(:immo_promo_task, phase: phase1, priority: 'critical')
      task2 = create(:immo_promo_task, phase: phase2, priority: 'high')

      critical_tasks = service.critical_path_analysis

      expect(critical_tasks).to be_an(Array)
      expect(critical_tasks.first).to be_a(Hash)
      expect(critical_tasks.first).to include(:phase, :is_on_critical_path, :slack_time)
    end
  end
end
