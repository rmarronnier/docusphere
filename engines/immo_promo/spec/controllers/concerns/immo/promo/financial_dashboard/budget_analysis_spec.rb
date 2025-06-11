require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboard::BudgetAnalysis, type: :concern do
  
  let(:controller_class) do
    Class.new do
      include Immo::Promo::FinancialDashboard::BudgetAnalysis
      
      attr_accessor :project
      
      def initialize(project = nil)
        @project = project
      end
      
      def immo_promo_engine
        double('engine', project_financial_dashboard_path: '/financial_dashboard')
      end
      
      def redirect_to(path)
        @redirect_path = path
      end
      
      def flash
        @flash ||= {}
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:controller) { controller_class.new(project) }

  describe '#variance_analysis' do
    it 'initializes budget service and sets variance data' do
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(double)
      allow(controller).to receive(:detailed_variance_analysis).and_return([])
      allow(controller).to receive(:analyze_variance_trends).and_return({})
      allow(controller).to receive(:analyze_category_performance).and_return({})
      allow(controller).to receive(:generate_variance_recommendations).and_return([])
      
      controller.variance_analysis
      
      expect(controller.instance_variable_get(:@variance_data)).to eq([])
      expect(controller.instance_variable_get(:@trends)).to eq({})
      expect(controller.instance_variable_get(:@category_performance)).to eq({})
      expect(controller.instance_variable_get(:@recommendations)).to eq([])
    end
  end

  describe '#cost_control' do
    it 'sets up cost tracking data' do
      budget_service = double('ProjectBudgetService')
      cost_tracking = {
        cost_overruns: [],
        top_expenses: [],
        total_spent: 100000
      }
      
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      allow(budget_service).to receive(:cost_tracking_report).and_return(cost_tracking)
      allow(controller).to receive(:analyze_cost_trends).and_return({})
      allow(controller).to receive(:suggest_cost_control_measures).and_return([])
      
      controller.cost_control
      
      expect(controller.instance_variable_get(:@cost_tracking)).to eq(cost_tracking)
      expect(controller.instance_variable_get(:@overruns)).to eq([])
      expect(controller.instance_variable_get(:@top_expenses)).to eq([])
    end
  end

  describe '#budget_scenarios' do
    it 'generates budget scenarios and risk assessment' do
      budget_service = double('ProjectBudgetService')
      base_forecast = { total: 1000000, timeline: [] }
      
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      allow(budget_service).to receive(:budget_forecast).and_return(base_forecast)
      allow(controller).to receive(:generate_detailed_scenarios).and_return({})
      allow(controller).to receive(:assess_budget_risks).and_return([])
      allow(controller).to receive(:develop_contingency_plans).and_return({})
      
      controller.budget_scenarios
      
      expect(controller.instance_variable_get(:@base_forecast)).to eq(base_forecast)
      expect(controller.instance_variable_get(:@scenarios)).to eq({})
      expect(controller.instance_variable_get(:@risk_assessment)).to eq([])
      expect(controller.instance_variable_get(:@contingency_plans)).to eq({})
    end
  end

  describe 'private methods' do
    let(:budget_service) { double('ProjectBudgetService') }
    
    before do
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      controller.instance_variable_set(:@budget_service, budget_service)
    end

    describe '#analyze_budget_line_variances' do
      it 'calculates variance for budget lines' do
        budget_lines = [
          {
            description: 'Construction costs',
            planned_amount: 100000,
            actual_amount: 110000
          },
          {
            description: 'Marketing costs',
            planned_amount: 50000,
            actual_amount: 45000
          }
        ]
        
        result = controller.send(:analyze_budget_line_variances, budget_lines)
        
        expect(result.length).to eq(2)
        
        # Test first line (overrun)
        first_line = result.first
        expect(first_line[:variance]).to eq(10000)
        expect(first_line[:variance_percent]).to eq(10.0)
        expect(first_line[:variance_category]).to eq('concerning')
        
        # Test second line (under budget)
        second_line = result.last
        expect(second_line[:variance]).to eq(-5000)
        expect(second_line[:variance_percent]).to eq(-10.0)
        expect(second_line[:variance_category]).to eq('concerning')
      end
      
      it 'handles zero planned amount' do
        budget_lines = [
          {
            description: 'Unexpected cost',
            planned_amount: 0,
            actual_amount: 5000
          }
        ]
        
        result = controller.send(:analyze_budget_line_variances, budget_lines)
        
        expect(result.first[:variance_percent]).to eq(0)
      end
    end

    describe '#categorize_variance' do
      it 'correctly categorizes variance levels' do
        expect(controller.send(:categorize_variance, 3.0)).to eq('acceptable')
        expect(controller.send(:categorize_variance, 8.0)).to eq('concerning')
        expect(controller.send(:categorize_variance, 18.0)).to eq('significant')
        expect(controller.send(:categorize_variance, 30.0)).to eq('critical')
        
        # Test negative variances
        expect(controller.send(:categorize_variance, -3.0)).to eq('acceptable')
        expect(controller.send(:categorize_variance, -18.0)).to eq('significant')
      end
    end

    describe '#generate_detailed_scenarios' do
      it 'creates multiple budget scenarios' do
        base_budget = { total: 1000000, categories: {} }
        
        allow(budget_service).to receive(:budget_summary).and_return(base_budget)
        allow(controller).to receive(:generate_optimistic_scenario).and_return({})
        allow(controller).to receive(:generate_pessimistic_scenario).and_return({})
        allow(controller).to receive(:generate_most_likely_scenario).and_return({})
        allow(controller).to receive(:generate_stress_test_scenario).and_return({})
        
        scenarios = controller.send(:generate_detailed_scenarios)
        
        expect(scenarios).to have_key(:optimistic)
        expect(scenarios).to have_key(:pessimistic)
        expect(scenarios).to have_key(:most_likely)
        expect(scenarios).to have_key(:stress_test)
      end
    end

    describe '#assess_budget_risks' do
      it 'identifies budget risks' do
        allow(controller).to receive(:calculate_overrun_probability).and_return(0.4)
        allow(controller).to receive(:assess_liquidity_risk).and_return({
          severity: 0.6,
          probability: 0.3
        })
        
        risks = controller.send(:assess_budget_risks)
        
        expect(risks.length).to eq(2)
        expect(risks.first[:type]).to eq('cost_overrun')
        expect(risks.last[:type]).to eq('liquidity')
      end
      
      it 'returns empty array for low risk projects' do
        allow(controller).to receive(:calculate_overrun_probability).and_return(0.1)
        allow(controller).to receive(:assess_liquidity_risk).and_return({
          severity: 0.2,
          probability: 0.1
        })
        
        risks = controller.send(:assess_budget_risks)
        
        expect(risks).to be_empty
      end
    end

    describe '#suggest_cost_control_measures' do
      it 'suggests measures based on cost analysis' do
        cost_tracking = {
          total_overrun_percent: 12,
          trend: 'increasing'
        }
        controller.instance_variable_set(:@cost_tracking, cost_tracking)
        
        allow(controller).to receive(:estimate_freeze_savings).and_return(50000)
        allow(controller).to receive(:estimate_process_savings).and_return(30000)
        
        measures = controller.send(:suggest_cost_control_measures)
        
        expect(measures.length).to eq(2)
        expect(measures.first[:priority]).to eq('high')
        expect(measures.first[:action]).to include('Gel des dépenses')
        expect(measures.last[:priority]).to eq('medium')
        expect(measures.last[:action]).to include('Révision des processus')
      end
    end
  end

  describe 'integration behavior' do
    it 'works with real project data' do
      # Test avec des données réelles quand disponibles
      skip 'Integration test - requires full project setup'
      
      real_project = create(:immo_promo_project, :with_budgets, organization: organization)
      real_controller = controller_class.new(real_project)
      
      expect { real_controller.variance_analysis }.not_to raise_error
      expect { real_controller.cost_control }.not_to raise_error
      expect { real_controller.budget_scenarios }.not_to raise_error
    end
  end
end