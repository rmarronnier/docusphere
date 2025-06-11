require 'rails_helper'

RSpec.describe Immo::Promo::ProjectResourceService::OptimizationRecommendations do
  let(:test_class) do
    Class.new do
      include Immo::Promo::ProjectResourceService::OptimizationRecommendations
      include Immo::Promo::ProjectResourceService::UtilizationMetrics
      include Immo::Promo::ProjectResourceService::WorkloadAnalysis
      
      attr_accessor :project, :optimization_service
      
      def initialize(project)
        @project = project
        @optimization_service = double('optimization_service')
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { test_class.new(project) }

  describe '#optimization_recommendations' do
    let!(:overloaded_stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:underutilized_stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:optimal_stakeholder) { create(:immo_promo_stakeholder, project: project) }

    before do
      # Mock utilization levels
      allow(service).to receive(:calculate_utilization_percentage).with(overloaded_stakeholder).and_return(120)
      allow(service).to receive(:calculate_utilization_percentage).with(underutilized_stakeholder).and_return(30)
      allow(service).to receive(:calculate_utilization_percentage).with(optimal_stakeholder).and_return(75)
      
      # Mock workload scores
      allow(service).to receive(:calculate_workload_score).with(overloaded_stakeholder).and_return(95)
      allow(service).to receive(:calculate_workload_score).with(underutilized_stakeholder).and_return(25)
      allow(service).to receive(:calculate_workload_score).with(optimal_stakeholder).and_return(70)
      
      # Mock optimization service
      allow(service.optimization_service).to receive(:optimize_assignments).and_return({
        recommendations: [],
        improvement_potential: 0.15
      })
    end

    it 'generates comprehensive recommendations' do
      recommendations = service.optimization_recommendations
      
      expect(recommendations).to include(
        :load_balancing,
        :resource_reallocation,
        :capacity_adjustments,
        :skill_optimization,
        :timeline_adjustments,
        :automation_opportunities
      )
    end

    it 'identifies load balancing opportunities' do
      recommendations = service.optimization_recommendations
      
      load_balancing = recommendations[:load_balancing]
      expect(load_balancing[:overloaded_count]).to eq(1)
      expect(load_balancing[:underutilized_count]).to eq(1)
      expect(load_balancing[:recommendations]).to be_an(Array)
      expect(load_balancing[:recommendations]).not_to be_empty
    end

    it 'suggests resource reallocations' do
      recommendations = service.optimization_recommendations
      
      reallocations = recommendations[:resource_reallocation]
      expect(reallocations).to be_an(Array)
      
      # Should suggest moving tasks from overloaded to underutilized
      reallocation = reallocations.first
      expect(reallocation[:from]).to eq(overloaded_stakeholder)
      expect(reallocation[:to]).to eq(underutilized_stakeholder)
      expect(reallocation[:reason]).to include('overloaded')
    end
  end

  describe '#generate_resource_reallocation_plan' do
    let!(:donor_stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:recipient_stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:movable_task) { create(:immo_promo_task, stakeholder: donor_stakeholder, status: 'pending', estimated_hours: 20) }
    let!(:in_progress_task) { create(:immo_promo_task, stakeholder: donor_stakeholder, status: 'in_progress') }

    before do
      allow(service).to receive(:calculate_utilization_percentage).with(donor_stakeholder).and_return(110)
      allow(service).to receive(:calculate_utilization_percentage).with(recipient_stakeholder).and_return(40)
    end

    it 'generates reallocation plan' do
      plan = service.generate_resource_reallocation_plan
      
      expect(plan).to include(
        :proposed_moves,
        :impact_analysis,
        :implementation_steps,
        :risk_assessment
      )
    end

    it 'proposes task moves from overloaded to underutilized resources' do
      plan = service.generate_resource_reallocation_plan
      
      moves = plan[:proposed_moves]
      expect(moves).to be_an(Array)
      
      move = moves.first
      expect(move[:task]).to eq(movable_task)
      expect(move[:from]).to eq(donor_stakeholder)
      expect(move[:to]).to eq(recipient_stakeholder)
      expect(move[:feasibility]).to eq('high')
    end

    it 'includes impact analysis' do
      plan = service.generate_resource_reallocation_plan
      
      impact = plan[:impact_analysis]
      expect(impact).to include(
        :utilization_before,
        :utilization_after,
        :balance_improvement,
        :affected_resources
      )
    end
  end

  describe 'private methods' do
    describe '#identify_load_imbalances' do
      let!(:overloaded) { create(:immo_promo_stakeholder, project: project) }
      let!(:underutilized) { create(:immo_promo_stakeholder, project: project) }

      before do
        allow(service).to receive(:calculate_utilization_percentage).with(overloaded).and_return(115)
        allow(service).to receive(:calculate_utilization_percentage).with(underutilized).and_return(25)
      end

      it 'identifies resource imbalances' do
        imbalances = service.send(:identify_load_imbalances)
        
        expect(imbalances[:overloaded]).to include(overloaded)
        expect(imbalances[:underutilized]).to include(underutilized)
        expect(imbalances[:optimal]).to be_empty
      end
    end

    describe '#suggest_capacity_adjustments' do
      context 'with overloaded resources' do
        let!(:overloaded) { create(:immo_promo_stakeholder, project: project) }
        
        before do
          allow(service).to receive(:calculate_utilization_percentage).with(overloaded).and_return(150)
          create_list(:immo_promo_task, 5, stakeholder: overloaded, estimated_hours: 30)
        end

        it 'suggests hiring or outsourcing' do
          adjustments = service.send(:suggest_capacity_adjustments)
          
          expect(adjustments).to include(
            match(/Envisager le recrutement/),
            match(/Externaliser certaines tâches/)
          )
        end
      end
    end

    describe '#identify_automation_opportunities' do
      let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:repetitive_tasks) do
        5.times.map do |i|
          create(:immo_promo_task,
            stakeholder: stakeholder,
            name: "Rapport hebdomadaire #{i}",
            task_type: 'reporting'
          )
        end
      end

      it 'identifies repetitive tasks for automation' do
        opportunities = service.send(:identify_automation_opportunities)
        
        expect(opportunities).to be_an(Array)
        expect(opportunities.first).to include(
          :task_type,
          :count,
          :total_hours,
          :automation_potential,
          :suggested_tools
        )
      end
    end

    describe '#calculate_reallocation_impact' do
      let(:donor) { create(:immo_promo_stakeholder, project: project) }
      let(:recipient) { create(:immo_promo_stakeholder, project: project) }
      let(:task) { create(:immo_promo_task, stakeholder: donor, estimated_hours: 20) }

      before do
        allow(service).to receive(:calculate_utilization_percentage).with(donor).and_return(110)
        allow(service).to receive(:calculate_utilization_percentage).with(recipient).and_return(40)
      end

      it 'calculates impact of task reallocation' do
        impact = service.send(:calculate_reallocation_impact, donor, recipient, task)
        
        expect(impact).to include(
          donor_utilization_before: 110,
          donor_utilization_after: be < 110,
          recipient_utilization_before: 40,
          recipient_utilization_after: be > 40,
          improvement_score: be > 0
        )
      end
    end
  end
end