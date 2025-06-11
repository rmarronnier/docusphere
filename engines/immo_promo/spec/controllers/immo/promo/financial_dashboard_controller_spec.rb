require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboardController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:budget_service) { instance_double('Immo::Promo::ProjectBudgetService') }

  before do
    sign_in user
    allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
    allow(budget_service).to receive(:budget_summary).and_return({})
    allow(budget_service).to receive(:cost_tracking_report).and_return({ by_category: {}, by_period: {} })
    allow(budget_service).to receive(:budget_forecast).and_return({})
    allow(budget_service).to receive(:cash_flow_analysis).and_return({})
    allow(budget_service).to receive(:budget_optimization_suggestions).and_return([])
  end

  describe 'GET #dashboard' do
    it 'returns a success response' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'initializes budget service and assigns variables' do
      get :dashboard, params: { project_id: project.id }
      expect(assigns(:budget_service)).to eq(budget_service)
      expect(assigns(:budget_summary)).to be_present
      expect(assigns(:cost_tracking)).to be_present
      expect(assigns(:forecast)).to be_present
      expect(assigns(:cash_flow)).to be_present
      expect(assigns(:optimization_suggestions)).to be_present
    end

    it 'responds to JSON format' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #variance_analysis' do
    before do
      allow(budget_service).to receive(:detailed_budget_breakdown).and_return([])
    end

    it 'returns a success response' do
      get :variance_analysis, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns variance analysis data' do
      get :variance_analysis, params: { project_id: project.id }
      expect(assigns(:variance_data)).to be_present
      expect(assigns(:trends)).to be_present
      expect(assigns(:category_performance)).to be_present
      expect(assigns(:recommendations)).to be_present
    end
  end

  describe 'GET #cost_control' do
    before do
      allow(budget_service).to receive(:cost_tracking_report).and_return({
        cost_overruns: [],
        top_expenses: []
      })
    end

    it 'returns a success response' do
      get :cost_control, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns cost control data' do
      get :cost_control, params: { project_id: project.id }
      expect(assigns(:cost_tracking)).to be_present
      expect(assigns(:overruns)).to be_present
      expect(assigns(:top_expenses)).to be_present
      expect(assigns(:cost_trends)).to be_present
      expect(assigns(:control_measures)).to be_present
    end
  end

  describe 'GET #cash_flow_management' do
    before do
      allow(budget_service).to receive(:cash_flow_analysis).and_return({
        liquidity_requirements: { next_3_months: Money.new(0, 'EUR'), next_6_months: Money.new(0, 'EUR') },
        payment_schedule: []
      })
    end

    it 'returns a success response' do
      get :cash_flow_management, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns cash flow data' do
      get :cash_flow_management, params: { project_id: project.id }
      expect(assigns(:cash_flow)).to be_present
      expect(assigns(:liquidity_forecast)).to be_present
      expect(assigns(:payment_schedule)).to be_present
      expect(assigns(:financing_recommendations)).to be_present
    end
  end

  describe 'GET #budget_scenarios' do
    before do
      allow(budget_service).to receive(:budget_forecast).and_return({
        projected_total_cost: Money.new(1000000, 'EUR')
      })
    end

    it 'returns a success response' do
      get :budget_scenarios, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns scenario data' do
      get :budget_scenarios, params: { project_id: project.id }
      expect(assigns(:base_forecast)).to be_present
      expect(assigns(:scenarios)).to be_present
      expect(assigns(:risk_assessment)).to be_present
      expect(assigns(:contingency_plans)).to be_present
    end
  end

  describe 'GET #profitability_analysis' do
    it 'returns a success response' do
      get :profitability_analysis, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns profitability data' do
      get :profitability_analysis, params: { project_id: project.id }
      expect(assigns(:profitability_data)).to be_present
      expect(assigns(:margin_analysis)).to be_present
      expect(assigns(:revenue_forecast)).to be_present
      expect(assigns(:roi_analysis)).to be_present
      expect(assigns(:value_optimization)).to be_present
    end
  end

  describe 'POST #approve_budget_adjustment' do
    let(:budget) { create(:immo_promo_budget, project: project) }
    let(:adjustment_params) do
      {
        amount: '10000',
        category: 'construction',
        justification: 'Unexpected costs',
        approval_level: 'manager'
      }
    end

    it 'approves budget adjustment successfully' do
      allow(controller).to receive(:create_budget_adjustment).and_return({
        success: true,
        record: { amount: 10000 }
      })

      post :approve_budget_adjustment, params: {
        project_id: project.id,
        budget_id: budget.id,
        adjustment: adjustment_params
      }

      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/financial_dashboard")
      expect(flash[:success]).to be_present
    end

    it 'handles adjustment failure' do
      allow(controller).to receive(:create_budget_adjustment).and_return({
        success: false,
        error: 'Invalid adjustment'
      })

      post :approve_budget_adjustment, params: {
        project_id: project.id,
        budget_id: budget.id,
        adjustment: adjustment_params
      }

      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #reallocate_budget' do
    let(:budget1) { create(:immo_promo_budget, project: project) }
    let(:budget2) { create(:immo_promo_budget, project: project) }
    let(:reallocation_params) do
      {
        from_budget_id: budget1.id,
        to_budget_id: budget2.id,
        amount: '5000',
        justification: 'Reallocation needed'
      }
    end

    it 'executes reallocation successfully' do
      allow(controller).to receive(:execute_budget_reallocation).and_return({
        success: true,
        reallocation: reallocation_params
      })

      post :reallocate_budget, params: {
        project_id: project.id,
        reallocation: reallocation_params
      }

      expect(flash[:success]).to be_present
    end
  end

  describe 'POST #set_budget_alert' do
    let(:alert_params) do
      {
        threshold_type: 'percentage',
        threshold_value: '90',
        notification_method: 'email'
      }
    end

    it 'creates budget alert successfully' do
      allow(controller).to receive(:create_budget_alert).and_return({
        success: true,
        alert: alert_params
      })

      post :set_budget_alert, params: {
        project_id: project.id,
        alert: alert_params
      }

      expect(flash[:success]).to be_present
    end
  end

  describe 'GET #generate_financial_report' do
    it 'generates PDF report' do
      get :generate_financial_report, params: { project_id: project.id }, format: :pdf
      expect(response).to be_successful
      expect(response.content_type).to include('application/pdf')
    end

    it 'generates XLSX report' do
      get :generate_financial_report, params: { project_id: project.id }, format: :xlsx
      expect(response).to be_successful
    end
  end

  describe 'GET #export_budget_data' do
    it 'exports as CSV by default' do
      get :export_budget_data, params: { project_id: project.id }
      expect(response).to be_successful
      expect(response.content_type).to include('text/csv')
    end

    it 'exports as JSON when specified' do
      get :export_budget_data, params: { project_id: project.id, format: 'json' }
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end

    it 'handles unsupported format' do
      get :export_budget_data, params: { project_id: project.id, format: 'xml' }
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #sync_accounting_system' do
    it 'syncs successfully' do
      allow(controller).to receive(:synchronize_with_accounting).and_return({
        success: true,
        updated_records: 25
      })

      post :sync_accounting_system, params: { project_id: project.id }
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/financial_dashboard")
      expect(flash[:success]).to be_present
      expect(flash[:info]).to be_present
    end

    it 'handles sync error' do
      allow(controller).to receive(:synchronize_with_accounting).and_return({
        success: false,
        error: 'Connection failed'
      })

      post :sync_accounting_system, params: { project_id: project.id }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'authorization' do
    it 'authorizes financial access' do
      expect(controller).to receive(:authorize).with(project, :manage_finances?)
      get :dashboard, params: { project_id: project.id }
    end
  end

  describe 'private methods' do
    it 'responds to financial calculation methods' do
      expect(controller).to respond_to(:calculate_profitability_metrics, true)
      expect(controller).to respond_to(:estimate_project_revenue, true)
      expect(controller).to respond_to(:assess_financial_health, true)
    end
  end
end