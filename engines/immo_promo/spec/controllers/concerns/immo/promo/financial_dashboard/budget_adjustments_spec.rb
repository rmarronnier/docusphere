require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboard::BudgetAdjustments, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::FinancialDashboard::BudgetAdjustments
      
      attr_accessor :project, :current_user, :params
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = ActionController::Parameters.new
      end
      
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirect_path = path
      end
      
      def redirect_back(fallback_location:)
        @redirect_path = fallback_location
      end
      
      def immo_promo_engine
        double('engine', 
          project_financial_dashboard_path: '/financial_dashboard',
          project_financial_dashboard_variance_analysis_path: '/variance_analysis'
        )
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:budget) { create(:immo_promo_budget, project: project) }
  let(:controller) { controller_class.new(project, user) }

  describe '#approve_budget_adjustment' do
    let(:adjustment_params) do
      {
        budget_id: budget.id,
        adjustment: {
          amount: 10000,
          category: 'construction',
          justification: 'Material cost increase',
          approval_level: 'project_manager'
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(adjustment_params)
    end

    it 'creates and approves budget adjustment' do
      allow(controller).to receive(:create_budget_adjustment).and_return({
        success: true,
        record: { budget: budget, amount: 10000 }
      })
      allow(controller).to receive(:log_budget_adjustment)
      allow(controller).to receive(:significant_adjustment?).and_return(false)
      
      controller.approve_budget_adjustment
      
      expect(controller.flash[:success]).to eq('Ajustement budgétaire approuvé')
    end

    context 'with significant adjustment' do
      it 'sends notifications' do
        allow(controller).to receive(:create_budget_adjustment).and_return({
          success: true,
          record: { budget: budget, amount: 50000 }
        })
        allow(controller).to receive(:log_budget_adjustment)
        allow(controller).to receive(:significant_adjustment?).and_return(true)
        
        expect(controller).to receive(:send_budget_adjustment_notifications)
        
        controller.approve_budget_adjustment
      end
    end
  end

  describe '#reallocate_budget' do
    let(:from_budget) { create(:immo_promo_budget, project: project, amount_cents: 100000_00) }
    let(:to_budget) { create(:immo_promo_budget, project: project, amount_cents: 50000_00) }
    let(:reallocation_params) do
      {
        reallocation: {
          from_budget_id: from_budget.id,
          to_budget_id: to_budget.id,
          amount: 20000,
          justification: 'Priority change'
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(reallocation_params)
    end

    it 'executes budget reallocation' do
      allow(controller).to receive(:execute_budget_reallocation).and_return({
        success: true,
        reallocation: reallocation_params[:reallocation]
      })
      allow(controller).to receive(:log_budget_reallocation)
      
      controller.reallocate_budget
      
      expect(controller.flash[:success]).to eq('Réallocation budgétaire effectuée')
    end
  end

  describe '#set_budget_alert' do
    let(:alert_params) do
      {
        alert: {
          threshold_type: 'percentage',
          threshold_value: 80,
          notification_method: 'email'
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(alert_params)
    end

    it 'creates budget alert' do
      allow(controller).to receive(:create_budget_alert).and_return({
        success: true,
        alert: alert_params[:alert]
      })
      
      controller.set_budget_alert
      
      expect(controller.flash[:success]).to eq('Alerte budgétaire configurée')
    end
  end
end