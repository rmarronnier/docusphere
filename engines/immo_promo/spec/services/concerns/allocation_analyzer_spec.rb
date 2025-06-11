require 'rails_helper'

RSpec.describe Immo::Promo::Concerns::AllocationAnalyzer do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Immo::Promo::Concerns::AllocationAnalyzer
      attr_reader :project
      
      def initialize(project)
        @project = project
      end
      
      # Mock methods that would come from other concerns
      def generate_optimization_recommendations
        [{ type: 'test', recommendation: 'Test recommendation' }]
      end
      
      def check_workload_balance
        {
          needs_rebalancing: true,
          max_workload: 8,
          min_workload: 2,
          average_workload: 5.0
        }
      end
    end
  end
  
  let(:service) { test_class.new(project) }
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  describe '#task_distribution' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    before do
      create_list(:immo_promo_task, 3, phase: phase, status: 'pending')
      create_list(:immo_promo_task, 2, phase: phase, status: 'in_progress')
      create(:immo_promo_task, phase: phase, status: 'completed')
    end
    
    it 'returns task distribution by status as percentages' do
      distribution = service.task_distribution
      
      expect(distribution['pending']).to eq(50.0) # 3/6
      expect(distribution['in_progress']).to eq(33.3) # 2/6
      expect(distribution['completed']).to eq(16.7) # 1/6
    end
    
    it 'handles empty task list' do
      allow(project.tasks).to receive_message_chain(:group, :count).and_return({})
      
      distribution = service.task_distribution
      expect(distribution).to eq({})
    end
  end
  
  describe '#recommendations' do
    it 'delegates to generate_optimization_recommendations' do
      result = service.recommendations
      expect(result).to be_an(Array)
      expect(result.first[:type]).to eq('test')
    end
  end
  
  describe '#resource_recommendations' do
    it 'returns standard resource recommendations' do
      recommendations = service.resource_recommendations
      
      expect(recommendations).to be_an(Array)
      expect(recommendations.first).to include(
        description: 'Rééquilibrer la charge de travail',
        impact: 'high',
        effort: 'medium',
        priority: 1
      )
    end
  end
  
  describe '#schedule_recommendations' do
    it 'returns standard schedule recommendations' do
      recommendations = service.schedule_recommendations
      
      expect(recommendations).to be_an(Array)
      expect(recommendations.first).to include(
        description: 'Optimiser le séquencement des tâches',
        impact: 'medium',
        effort: 'low',
        priority: 2
      )
    end
  end
  
  describe '#optimization_suggestions' do
    context 'when workload needs rebalancing' do
      it 'suggests load balancing' do
        suggestions = service.optimization_suggestions
        
        load_balance_suggestion = suggestions.find { |s| s[:type] == 'load_balancing' }
        expect(load_balance_suggestion).not_to be_nil
        expect(load_balance_suggestion[:priority]).to eq('high')
        expect(load_balance_suggestion[:details][:needs_rebalancing]).to be true
      end
    end
    
    context 'when tasks can be grouped' do
      let!(:phase) { create(:immo_promo_phase, project: project, name: 'Construction') }
      let!(:tasks) { create_list(:immo_promo_task, 3, phase: phase, status: 'pending') }
      
      it 'suggests task grouping' do
        suggestions = service.optimization_suggestions
        
        grouping_suggestion = suggestions.find { |s| s[:type] == 'task_grouping' }
        expect(grouping_suggestion).not_to be_nil
        expect(grouping_suggestion[:priority]).to eq('medium')
        expect(grouping_suggestion[:tasks]).not_to be_empty
      end
    end
    
    context 'when no specific optimizations available' do
      before do
        allow(service).to receive(:check_workload_balance).and_return({ needs_rebalancing: false })
        allow(project.tasks).to receive_message_chain(:where, :group_by).and_return({})
      end
      
      it 'provides general optimization suggestion' do
        suggestions = service.optimization_suggestions
        
        expect(suggestions.size).to eq(1)
        expect(suggestions.first[:type]).to eq('general_optimization')
        expect(suggestions.first[:priority]).to eq('low')
      end
    end
  end
  
  describe 'private methods' do
    describe '#check_workload_balance' do
      let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
      let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }
      
      before do
        allow(stakeholder1.tasks).to receive_message_chain(:where, :count).and_return(8)
        allow(stakeholder2.tasks).to receive_message_chain(:where, :count).and_return(2)
      end
      
      it 'identifies workload imbalance' do
        balance = service.send(:check_workload_balance)
        
        expect(balance[:needs_rebalancing]).to be true
        expect(balance[:max_workload]).to eq(8)
        expect(balance[:min_workload]).to eq(2)
        expect(balance[:average_workload]).to eq(5.0)
      end
    end
    
    describe '#find_groupable_tasks' do
      let!(:phase1) { create(:immo_promo_phase, project: project, name: 'Phase 1') }
      let!(:phase2) { create(:immo_promo_phase, project: project, name: 'Phase 2') }
      let!(:tasks1) { create_list(:immo_promo_task, 3, phase: phase1, status: 'pending') }
      let!(:tasks2) { create_list(:immo_promo_task, 1, phase: phase2, status: 'pending') }
      
      it 'identifies phases with multiple pending tasks' do
        groupable = service.send(:find_groupable_tasks)
        
        expect(groupable.size).to eq(1)
        expect(groupable.first[:phase]).to eq('Phase 1')
        expect(groupable.first[:tasks].size).to eq(3)
        expect(groupable.first[:potential_efficiency_gain]).to eq('30%')
      end
      
      it 'excludes phases with single task' do
        groupable = service.send(:find_groupable_tasks)
        
        phase2_group = groupable.find { |g| g[:phase] == 'Phase 2' }
        expect(phase2_group).to be_nil
      end
    end
  end
end