require 'rails_helper'

RSpec.describe Immo::Promo::Concerns::AllocationOptimizer do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Immo::Promo::Concerns::AllocationOptimizer
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
  
  describe '#optimize_team_allocation' do
    it 'returns a comprehensive allocation analysis' do
      result = service.optimize_team_allocation
      
      expect(result).to have_key(:current_status)
      expect(result).to have_key(:rebalancing)
      expect(result).to have_key(:bottlenecks)
      expect(result).to have_key(:recommendations)
    end
    
    context 'with overloaded stakeholders' do
      let!(:overloaded_stakeholder) do
        create(:immo_promo_stakeholder, project: project).tap do |s|
          allow(s).to receive(:workload_status).and_return(:overloaded)
        end
      end
      
      before do
        allow(project.stakeholders).to receive(:overloaded).and_return([overloaded_stakeholder])
      end
      
      it 'identifies overloaded stakeholders' do
        result = service.optimize_team_allocation
        expect(result[:current_status][:overloaded]).to include(overloaded_stakeholder)
      end
    end
  end
  
  describe '#optimize_resource_allocation' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:unassigned_task) { create(:immo_promo_task, phase: phase, stakeholder: nil) }
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor') }
    
    before do
      allow(service).to receive(:suggest_stakeholder_for_task).and_return(stakeholder)
    end
    
    it 'assigns stakeholders to unassigned tasks' do
      result = service.optimize_resource_allocation
      
      expect(result[:success]).to be true
      expect(result[:optimized_assignments]).to be_an(Array)
      expect(result[:optimized_assignments].first[:task_id]).to eq(unassigned_task.id)
      expect(result[:optimized_assignments].first[:stakeholder_id]).to eq(stakeholder.id)
    end
  end
  
  describe 'private methods' do
    describe '#identify_bottlenecks' do
      context 'with critical overloaded stakeholders' do
        let!(:critical_stakeholder) do
          create(:immo_promo_stakeholder, 
            project: project, 
            is_critical: true
          )
        end
        
        before do
          allow(project.stakeholders).to receive_message_chain(:where, :overloaded)
            .and_return([critical_stakeholder])
        end
        
        it 'identifies critical resource overload' do
          bottlenecks = service.send(:identify_bottlenecks)
          
          critical_bottleneck = bottlenecks.find { |b| b[:type] == :critical_resource_overload }
          expect(critical_bottleneck).not_to be_nil
          expect(critical_bottleneck[:severity]).to eq(:high)
        end
      end
      
      context 'with single point of failure' do
        before do
          allow(project.stakeholders).to receive_message_chain(:group, :count)
            .and_return({ 'architect' => 1, 'contractor' => 3 })
        end
        
        it 'identifies single points of failure' do
          bottlenecks = service.send(:identify_bottlenecks)
          
          spof = bottlenecks.find { |b| b[:type] == :single_point_of_failure }
          expect(spof).not_to be_nil
          expect(spof[:stakeholder_type]).to eq('architect')
          expect(spof[:severity]).to eq(:medium)
        end
      end
    end
    
    describe '#generate_optimization_recommendations' do
      context 'with poor performers' do
        let!(:poor_performer) do
          create(:immo_promo_stakeholder, project: project).tap do |s|
            allow(s).to receive(:performance_rating).and_return(:poor)
          end
        end
        
        it 'recommends performance improvement' do
          # Ensure the poor_performer is included in the stakeholders
          allow(project.stakeholders).to receive(:each).and_yield(poor_performer)
          
          recommendations = service.send(:generate_optimization_recommendations)
          
          perf_rec = recommendations.find { |r| r[:type] == :performance_improvement }
          expect(perf_rec).not_to be_nil
          expect(perf_rec[:stakeholder]).to eq(poor_performer)
          expect(perf_rec[:priority]).to eq(:medium)
        end
      end
      
      context 'with missing stakeholder types' do
        before do
          allow(service).to receive(:identify_missing_stakeholder_types).and_return(['engineer'])
        end
        
        it 'recommends resource addition' do
          recommendations = service.send(:generate_optimization_recommendations)
          
          resource_rec = recommendations.find { |r| r[:type] == :resource_addition }
          expect(resource_rec).not_to be_nil
          expect(resource_rec[:stakeholder_type]).to eq('engineer')
          expect(resource_rec[:priority]).to eq(:high)
        end
      end
    end
    
    describe '#required_stakeholder_types_for_phase' do
      it 'returns correct types for studies phase' do
        types = service.send(:required_stakeholder_types_for_phase, 'studies')
        expect(types).to match_array(['architect', 'engineer'])
      end
      
      it 'returns correct types for construction phase' do
        types = service.send(:required_stakeholder_types_for_phase, 'construction')
        expect(types).to match_array(['architect', 'engineer', 'contractor', 'control_office'])
      end
      
      it 'returns empty array for unknown phase' do
        types = service.send(:required_stakeholder_types_for_phase, 'unknown')
        expect(types).to eq([])
      end
    end
    
    describe '#calculate_workload_change' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      
      before do
        allow(stakeholder).to receive(:workload_status).and_return(:busy)
        allow(stakeholder.tasks).to receive_message_chain(:where, :count).and_return(5)
      end
      
      it 'calculates workload change for adding task' do
        result = service.send(:calculate_workload_change, stakeholder, 1)
        expect(result).to eq('busy → busy')
      end
      
      it 'calculates workload change for removing task' do
        result = service.send(:calculate_workload_change, stakeholder, -2)
        expect(result).to eq('busy → partially_available')
      end
    end
  end
end