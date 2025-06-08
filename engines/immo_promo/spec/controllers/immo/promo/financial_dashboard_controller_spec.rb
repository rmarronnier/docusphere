require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboardController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { 
    create(:immo_promo_project, 
      organization: organization, 
      project_manager: user,
      total_budget_cents: 10_000_000_00 # 10M EUR
    ) 
  }
  
  before do
    sign_in user
    allow(controller).to receive(:current_organization).and_return(organization)
  end

  describe 'GET #dashboard' do
    let!(:budget) { create(:immo_promo_budget, project: project, version: 'current') }
    let!(:budget_lines) { create_list(:immo_promo_budget_line, 5, budget: budget) }

    it 'returns http success' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads financial overview' do
      get :dashboard, params: { project_id: project.id }
      
      expect(assigns(:financial_overview)).to be_present
      expect(assigns(:financial_overview)).to include(
        :total_budget,
        :committed,
        :spent,
        :remaining
      )
    end

    it 'calculates budget health metrics' do
      get :dashboard, params: { project_id: project.id }
      
      expect(assigns(:budget_health)).to be_present
      expect(assigns(:budget_health)[:status]).to be_in(%w[healthy warning critical])
    end

    it 'loads recent transactions' do
      get :dashboard, params: { project_id: project.id }
      
      expect(assigns(:recent_transactions)).to be_present
      expect(assigns(:cost_trends)).to be_present
    end
  end

  describe 'GET #variance_analysis' do
    let!(:budget) { create(:immo_promo_budget, project: project) }
    let!(:budget_lines) do
      [
        create(:immo_promo_budget_line, budget: budget, category: 'construction', planned_amount_cents: 5_000_000_00, actual_amount_cents: 5_500_000_00),
        create(:immo_promo_budget_line, budget: budget, category: 'studies', planned_amount_cents: 500_000_00, actual_amount_cents: 450_000_00),
        create(:immo_promo_budget_line, budget: budget, category: 'fees', planned_amount_cents: 1_000_000_00, actual_amount_cents: 1_100_000_00)
      ]
    end

    it 'returns http success' do
      get :variance_analysis, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'calculates variance by category' do
      get :variance_analysis, params: { project_id: project.id }
      
      variances = assigns(:variance_by_category)
      expect(variances).to be_present
      expect(variances['construction'][:variance_percentage]).to eq(10.0)
      expect(variances['studies'][:variance_percentage]).to eq(-10.0)
    end

    it 'identifies top variances' do
      get :variance_analysis, params: { project_id: project.id }
      
      top_variances = assigns(:top_variances)
      expect(top_variances).to be_present
      expect(top_variances.first[:category]).to eq('construction')
    end

    it 'provides variance explanations' do
      get :variance_analysis, params: { project_id: project.id }
      
      expect(assigns(:variance_explanations)).to be_present
    end
  end

  describe 'GET #cost_control' do
    let!(:budget) { create(:immo_promo_budget, project: project) }

    it 'returns http success' do
      get :cost_control, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads cost control measures' do
      get :cost_control, params: { project_id: project.id }
      
      expect(assigns(:cost_drivers)).to be_present
      expect(assigns(:savings_opportunities)).to be_present
      expect(assigns(:risk_items)).to be_present
    end

    it 'calculates burn rate' do
      get :cost_control, params: { project_id: project.id }
      
      burn_rate = assigns(:burn_rate)
      expect(burn_rate).to be_present
      expect(burn_rate).to include(:daily, :weekly, :monthly)
    end

    it 'projects cost at completion' do
      get :cost_control, params: { project_id: project.id }
      
      projections = assigns(:cost_projections)
      expect(projections).to include(:estimated_at_completion, :variance_at_completion)
    end
  end

  describe 'GET #cash_flow_management' do
    it 'returns http success' do
      get :cash_flow_management, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'generates cash flow forecast' do
      get :cash_flow_management, params: { project_id: project.id }
      
      cash_flow = assigns(:cash_flow_forecast)
      expect(cash_flow).to be_present
      expect(cash_flow.first).to include(:month, :inflows, :outflows, :net, :cumulative)
    end

    it 'identifies funding gaps' do
      get :cash_flow_management, params: { project_id: project.id }
      
      funding_gaps = assigns(:funding_gaps)
      expect(funding_gaps).to be_present
    end

    it 'calculates working capital needs' do
      get :cash_flow_management, params: { project_id: project.id }
      
      working_capital = assigns(:working_capital_analysis)
      expect(working_capital).to include(:current_needs, :peak_needs, :timing)
    end
  end

  describe 'GET #budget_scenarios' do
    let!(:budget) { create(:immo_promo_budget, project: project) }

    it 'returns http success' do
      get :budget_scenarios, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'generates multiple scenarios' do
      get :budget_scenarios, params: { project_id: project.id }
      
      scenarios = assigns(:scenarios)
      expect(scenarios).to include(:optimistic, :realistic, :pessimistic)
      expect(scenarios[:optimistic][:total]).to be < scenarios[:pessimistic][:total]
    end

    it 'includes stress test scenario' do
      get :budget_scenarios, params: { project_id: project.id }
      
      stress_test = assigns(:stress_test_results)
      expect(stress_test).to be_present
      expect(stress_test).to include(:impact_factors, :total_impact, :mitigation_required)
    end

    it 'provides sensitivity analysis' do
      get :budget_scenarios, params: { project_id: project.id }
      
      sensitivity = assigns(:sensitivity_analysis)
      expect(sensitivity).to be_present
      expect(sensitivity).to include(:construction_costs, :interest_rates, :sales_prices)
    end
  end

  describe 'GET #profitability_analysis' do
    it 'returns http success' do
      get :profitability_analysis, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'calculates profitability metrics' do
      get :profitability_analysis, params: { project_id: project.id }
      
      profitability = assigns(:profitability_metrics)
      expect(profitability).to include(
        :gross_margin,
        :net_margin,
        :roi,
        :irr,
        :payback_period
      )
    end

    it 'provides margin breakdown' do
      get :profitability_analysis, params: { project_id: project.id }
      
      margin_analysis = assigns(:margin_analysis)
      expect(margin_analysis).to be_present
      expect(margin_analysis).to include(:by_lot_type, :by_phase)
    end
  end

  describe 'POST #approve_budget_adjustment' do
    let(:budget) { create(:immo_promo_budget, project: project) }
    
    context 'with valid adjustment' do
      it 'approves budget adjustment' do
        post :approve_budget_adjustment, params: {
          project_id: project.id,
          budget_id: budget.id,
          adjustment: {
            amount_cents: 500_000_00,
            category: 'construction',
            reason: 'Additional foundation work required',
            supporting_documents: ['quote.pdf']
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_financial_variance_analysis_path(project))
        expect(flash[:success]).to be_present
        expect(budget.reload.budget_lines.count).to be > 0
      end
    end

    context 'exceeding approval limits' do
      it 'requires higher approval' do
        post :approve_budget_adjustment, params: {
          project_id: project.id,
          budget_id: budget.id,
          adjustment: {
            amount_cents: 5_000_000_00, # 50% of budget
            category: 'construction',
            reason: 'Major scope change'
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_financial_variance_analysis_path(project))
        expect(flash[:warning]).to match(/Approbation requise/)
      end
    end
  end

  describe 'POST #reallocate_budget' do
    let(:budget) { create(:immo_promo_budget, project: project) }
    let!(:source_line) { create(:immo_promo_budget_line, budget: budget, category: 'contingency', planned_amount_cents: 1_000_000_00) }
    let!(:target_line) { create(:immo_promo_budget_line, budget: budget, category: 'construction', planned_amount_cents: 5_000_000_00) }

    it 'reallocates budget between lines' do
      post :reallocate_budget, params: {
        project_id: project.id,
        reallocation: {
          source_category: 'contingency',
          target_category: 'construction',
          amount_cents: 200_000_00,
          justification: 'Cover unexpected costs'
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_financial_dashboard_path(project))
      expect(flash[:success]).to be_present
      
      source_line.reload
      target_line.reload
      expect(source_line.planned_amount_cents).to eq(800_000_00)
      expect(target_line.planned_amount_cents).to eq(5_200_000_00)
    end
  end

  describe 'POST #set_budget_alert' do
    it 'configures budget alert' do
      post :set_budget_alert, params: {
        project_id: project.id,
        alert: {
          alert_type: 'budget_overrun',
          threshold: 90,
          recipients: ['pm@example.com', 'cfo@example.com'],
          frequency: 'weekly'
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_financial_cost_control_path(project))
      expect(flash[:success]).to match(/Alerte configurée/)
    end
  end

  describe 'GET #generate_financial_report' do
    it 'generates comprehensive financial report' do
      get :generate_financial_report, params: {
        project_id: project.id,
        format: :pdf
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to match(/rapport_financier/)
    end

    it 'includes all financial sections' do
      get :generate_financial_report, params: {
        project_id: project.id,
        format: :pdf,
        sections: ['overview', 'variance', 'cash_flow', 'profitability']
      }
      
      report_data = assigns(:report_data)
      expect(report_data[:sections]).to include('overview', 'variance', 'cash_flow', 'profitability')
    end
  end

  describe 'GET #export_budget_data' do
    it 'exports budget data as Excel' do
      get :export_budget_data, params: {
        project_id: project.id,
        format: :xlsx
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/spreadsheetml/)
    end

    it 'exports budget data as CSV' do
      get :export_budget_data, params: {
        project_id: project.id,
        format: :csv
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv')
    end
  end

  describe 'POST #sync_accounting_system' do
    it 'synchronizes with external accounting' do
      post :sync_accounting_system, params: {
        project_id: project.id,
        sync_options: {
          system: 'sap',
          include_actuals: true,
          include_commitments: true
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_financial_dashboard_path(project))
      expect(flash[:success]).to match(/Synchronisation/)
    end
  end

  describe 'JSON API responses' do
    it 'returns financial overview as JSON' do
      get :dashboard, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('financial_overview', 'budget_health', 'cost_trends')
    end

    it 'returns cash flow data as JSON' do
      get :cash_flow_management, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('cash_flow_forecast', 'funding_gaps')
    end
  end
end