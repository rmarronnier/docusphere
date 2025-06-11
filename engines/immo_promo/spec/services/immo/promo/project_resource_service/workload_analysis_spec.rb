require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService::WorkloadAnalysis do
  let(:test_class) do
    Class.new do
      include Immo::Promo::ProjectResourceService::WorkloadAnalysis
      
      attr_accessor :project
      
      def initialize(project)
        @project = project
      end
      
      # Mock method from UtilizationMetrics module
      def calculate_utilization_percentage(stakeholder)
        75.0
      end
      
      # Mock method from ResourceAllocation module
      def resource_status(utilization)
        case utilization
        when 0..30 then 'available'
        when 31..70 then 'partially_allocated'
        when 71..100 then 'fully_allocated'
        else 'overloaded'
        end
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { test_class.new(project) }

  describe '#stakeholder_workload_analysis' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:task1) { create(:immo_promo_task, phase: phase, stakeholder: stakeholder1, status: 'in_progress', estimated_hours: 20) }
    let!(:task2) { create(:immo_promo_task, phase: phase, stakeholder: stakeholder1, status: 'completed', estimated_hours: 10) }

    it 'returns comprehensive workload analysis for all stakeholders' do
      analysis = service.stakeholder_workload_analysis
      
      expect(analysis).to be_an(Array)
      expect(analysis.length).to eq(2)
      
      first_stakeholder_analysis = analysis.first
      expect(first_stakeholder_analysis).to include(
        :stakeholder,
        :workload,
        :tasks,
        :availability,
        :efficiency_metrics
      )
    end

    it 'includes stakeholder summary' do
      analysis = service.stakeholder_workload_analysis
      stakeholder_summary = analysis.first[:stakeholder]
      
      expect(stakeholder_summary).to include(
        id: stakeholder1.id,
        name: stakeholder1.name,
        type: stakeholder1.stakeholder_type,
        status: 'active'
      )
    end

    it 'calculates workload correctly' do
      analysis = service.stakeholder_workload_analysis
      workload = analysis.first[:workload]
      
      expect(workload).to include(
        active_tasks: 1,
        completed_tasks: 1,
        total_hours_allocated: 20,
        utilization_percentage: 75.0,
        workload_percentage: 75.0
      )
    end

    it 'provides task load details grouped by status' do
      analysis = service.stakeholder_workload_analysis
      tasks = analysis.first[:tasks]
      
      expect(tasks).to have_key('in_progress')
      expect(tasks).to have_key('completed')
      
      in_progress = tasks['in_progress']
      expect(in_progress[:count]).to eq(1)
      expect(in_progress[:total_hours]).to eq(20)
      expect(in_progress[:tasks].first).to include(
        id: task1.id,
        name: task1.name
      )
    end
  end

  describe 'private methods' do
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }

    describe '#calculate_efficiency_metrics' do
      context 'with no completed tasks' do
        it 'returns default metrics' do
          metrics = service.send(:calculate_efficiency_metrics, stakeholder)
          
          expect(metrics).to eq({
            tasks_completed: 0,
            on_time_delivery_rate: 0,
            average_task_duration: 0,
            efficiency_score: 0
          })
        end
      end

      context 'with completed tasks' do
        let!(:completed_task) do
          create(:immo_promo_task,
            stakeholder: stakeholder,
            status: 'completed',
            start_date: 10.days.ago,
            end_date: 5.days.ago,
            actual_start_date: 10.days.ago,
            actual_end_date: 4.days.ago
          )
        end

        it 'calculates metrics correctly' do
          metrics = service.send(:calculate_efficiency_metrics, stakeholder)
          
          expect(metrics[:tasks_completed]).to eq(1)
          expect(metrics[:on_time_delivery_rate]).to eq(100.0)
          expect(metrics[:efficiency_score]).to be > 0
        end
      end
    end

    describe '#calculate_efficiency_score' do
      it 'returns default score when no performance rating' do
        # Since performance_rating doesn't exist in model, it will return default
        expect(service.send(:calculate_efficiency_score, stakeholder)).to eq(70)
      end
    end
  end
end