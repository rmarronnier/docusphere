require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboard::CashFlowManagement, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::FinancialDashboard::CashFlowManagement
      
      attr_accessor :project
      
      def initialize(project = nil)
        @project = project
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:controller) { controller_class.new(project) }

  describe '#cash_flow_management' do
    let(:budget_service) { double('ProjectBudgetService') }
    
    before do
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      allow(budget_service).to receive(:cash_flow_analysis).and_return({
        current_balance: Money.new(100000, 'EUR'),
        projected_inflows: [],
        projected_outflows: [],
        liquidity_requirements: {
          next_3_months: Money.new(50000, 'EUR'),
          next_6_months: Money.new(100000, 'EUR')
        }
      })
    end

    it 'initializes budget service and sets cash flow data' do
      allow(controller).to receive(:forecast_liquidity_needs).and_return({})
      allow(controller).to receive(:optimize_payment_schedule).and_return({})
      allow(controller).to receive(:assess_financing_needs).and_return({})
      
      controller.cash_flow_management
      
      expect(controller.instance_variable_get(:@cash_flow)).to be_present
      expect(controller.instance_variable_get(:@liquidity_forecast)).to eq({})
      expect(controller.instance_variable_get(:@payment_schedule)).to eq({})
      expect(controller.instance_variable_get(:@financing_recommendations)).to eq({})
    end
  end

  describe '#forecast_liquidity' do
    let(:budget_service) { double('ProjectBudgetService') }
    
    before do
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      allow(budget_service).to receive(:liquidity_forecast).and_return({
        next_month: Money.new(20000, 'EUR'),
        next_quarter: Money.new(60000, 'EUR')
      })
    end

    it 'forecasts liquidity requirements' do
      controller.instance_variable_set(:@budget_service, budget_service)
      
      result = controller.forecast_liquidity
      
      expect(result).to include(
        :immediate_needs,
        :medium_term_needs,
        :critical_periods
      )
    end
  end

  describe '#optimize_cash_flow' do
    it 'provides cash flow optimization recommendations' do
      result = controller.optimize_cash_flow
      
      expect(result).to include(
        :payment_optimization,
        :collection_acceleration,
        :financing_options
      )
    end
  end
end