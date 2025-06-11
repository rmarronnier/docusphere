require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoringController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:risk_service) { instance_double('ProjectRiskService') }

  before do
    sign_in user
    # Mock the inner service classes
    stub_const('Immo::Promo::RiskMonitoringController::ProjectRiskService', risk_service.class)
    allow(risk_service.class).to receive(:new).and_return(risk_service)
    allow(risk_service).to receive(:risk_overview).and_return({})
    allow(risk_service).to receive(:active_risks).and_return([])
    allow(risk_service).to receive(:generate_risk_matrix).and_return({})
    allow(risk_service).to receive(:mitigation_tracking).and_return({})
  end

  describe 'GET #dashboard' do
    it 'returns a success response' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'initializes risk service and assigns variables' do
      get :dashboard, params: { project_id: project.id }
      expect(assigns(:risk_service)).to eq(risk_service)
      expect(assigns(:risk_overview)).to be_present
      expect(assigns(:active_risks)).to be_present
      expect(assigns(:risk_matrix)).to be_present
      expect(assigns(:mitigation_status)).to be_present
      expect(assigns(:alerts)).to be_present
    end

    it 'responds to JSON format' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #risk_register' do
    it 'returns a success response' do
      get :risk_register, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns risk data' do
      get :risk_register, params: { project_id: project.id }
      expect(assigns(:risks)).to be_present
      expect(assigns(:risks_by_category)).to be_present
      expect(assigns(:risks_by_severity)).to be_present
      expect(assigns(:risks_by_status)).to be_present
    end

    it 'applies filters when provided' do
      get :risk_register, params: { 
        project_id: project.id, 
        filters: { category: 'financial', severity: 'high' }
      }
      expect(assigns(:filters)).to eq({ 'category' => 'financial', 'severity' => 'high' })
    end
  end

  describe 'GET #alert_center' do
    before do
      alert_service = instance_double('AlertService')
      stub_const('Immo::Promo::RiskMonitoringController::AlertService', alert_service.class)
      allow(alert_service.class).to receive(:new).and_return(alert_service)
      allow(alert_service).to receive(:active_alerts).and_return([])
      allow(alert_service).to receive(:alert_history).and_return([])
      allow(alert_service).to receive(:configurations).and_return([])
      allow(alert_service).to receive(:available_channels).and_return([])
    end

    it 'returns a success response' do
      get :alert_center, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns alert data' do
      get :alert_center, params: { project_id: project.id }
      expect(assigns(:active_alerts)).to be_present
      expect(assigns(:alert_history)).to be_present
      expect(assigns(:alert_configurations)).to be_present
      expect(assigns(:notification_channels)).to be_present
    end
  end

  describe 'GET #early_warning_system' do
    before do
      warning_service = instance_double('EarlyWarningService')
      stub_const('Immo::Promo::RiskMonitoringController::EarlyWarningService', warning_service.class)
      allow(warning_service.class).to receive(:new).and_return(warning_service)
      allow(warning_service).to receive(:calculate_indicators).and_return({})
      allow(warning_service).to receive(:analyze_trends).and_return({})
      allow(warning_service).to receive(:generate_predictive_alerts).and_return([])
      allow(warning_service).to receive(:check_thresholds).and_return([])
    end

    it 'returns a success response' do
      get :early_warning_system, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns warning system data' do
      get :early_warning_system, params: { project_id: project.id }
      expect(assigns(:warning_indicators)).to be_present
      expect(assigns(:trend_analysis)).to be_present
      expect(assigns(:predictive_alerts)).to be_present
      expect(assigns(:threshold_violations)).to be_present
    end
  end

  describe 'POST #create_risk' do
    let(:valid_risk_params) do
      {
        title: 'Test Risk',
        description: 'Test description',
        category: 'financial',
        probability: 'medium',
        impact: 'major',
        risk_owner_id: user.id,
        detection_date: Date.current,
        target_resolution_date: Date.current + 30.days
      }
    end

    it 'creates a new risk successfully' do
      expect {
        post :create_risk, params: { project_id: project.id, risk: valid_risk_params }
      }.to change(Immo::Promo::Risk, :count).by(1)
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/risk_monitoring/risk_register")
      expect(flash[:success]).to be_present
    end

    it 'handles creation failure' do
      post :create_risk, params: { project_id: project.id, risk: { title: '' } }
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #update_risk_assessment' do
    let(:risk) { create(:immo_promo_risk, project: project) }
    let(:assessment_params) do
      {
        probability: 'high',
        impact: 'major',
        notes: 'Updated assessment',
        reassessment_reason: 'New information'
      }
    end

    it 'updates risk assessment successfully' do
      allow(controller).to receive(:create_risk_assessment).and_return({ success: true })
      
      post :update_risk_assessment, params: {
        project_id: project.id,
        risk_id: risk.id,
        assessment: assessment_params
      }
      
      expect(flash[:success]).to be_present
    end

    it 'handles assessment failure' do
      allow(controller).to receive(:create_risk_assessment).and_return({ 
        success: false, 
        error: 'Assessment failed' 
      })
      
      post :update_risk_assessment, params: {
        project_id: project.id,
        risk_id: risk.id,
        assessment: assessment_params
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #create_mitigation_action' do
    let(:risk) { create(:immo_promo_risk, project: project) }
    let(:action_params) do
      {
        action_type: 'mitigate',
        description: 'Mitigation action',
        responsible_id: user.id,
        due_date: Date.current + 15.days,
        cost_estimate: '5000',
        effectiveness_estimate: '80'
      }
    end

    it 'creates mitigation action successfully' do
      expect {
        post :create_mitigation_action, params: {
          project_id: project.id,
          risk_id: risk.id,
          action: action_params
        }
      }.to change(risk.mitigation_actions, :count).by(1)
      
      expect(flash[:success]).to be_present
    end

    it 'handles creation failure' do
      post :create_mitigation_action, params: {
        project_id: project.id,
        risk_id: risk.id,
        action: { description: '' }
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #configure_alert' do
    let(:alert_params) do
      {
        alert_type: 'risk_threshold',
        threshold_value: '10',
        comparison_operator: 'greater_than',
        notification_channels: 'email',
        recipients: 'admin@example.com',
        active: '1'
      }
    end

    it 'configures alert successfully' do
      allow(controller).to receive(:create_or_update_alert_configuration).and_return({ success: true })
      
      post :configure_alert, params: { project_id: project.id, alert: alert_params }
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/risk_monitoring/alert_center")
      expect(flash[:success]).to be_present
    end

    it 'handles configuration failure' do
      allow(controller).to receive(:create_or_update_alert_configuration).and_return({ 
        success: false, 
        error: 'Configuration failed' 
      })
      
      post :configure_alert, params: { project_id: project.id, alert: alert_params }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #acknowledge_alert' do
    let(:alert) { instance_double('Alert') }

    before do
      allow(Alert).to receive(:find).and_return(alert)
    end

    it 'acknowledges alert successfully' do
      allow(alert).to receive(:acknowledge!).and_return(true)
      
      post :acknowledge_alert, params: { project_id: project.id, alert_id: '1' }
      
      expect(flash[:success]).to be_present
    end

    it 'handles acknowledgment failure' do
      allow(alert).to receive(:acknowledge!).and_return(false)
      
      post :acknowledge_alert, params: { project_id: project.id, alert_id: '1' }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'GET #risk_report' do
    it 'generates PDF risk report' do
      get :risk_report, params: { project_id: project.id }, format: :pdf
      expect(response).to be_successful
      expect(response.content_type).to include('application/pdf')
    end

    it 'generates XLSX risk report' do
      get :risk_report, params: { project_id: project.id }, format: :xlsx
      expect(response).to be_successful
    end
  end

  describe 'GET #risk_matrix_export' do
    before do
      allow(risk_service).to receive(:generate_detailed_risk_matrix).and_return({})
    end

    it 'exports risk matrix as JSON' do
      get :risk_matrix_export, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end

    it 'exports risk matrix as SVG' do
      get :risk_matrix_export, params: { project_id: project.id }, format: :svg
      expect(response).to be_successful
      expect(response.content_type).to include('image/svg+xml')
    end
  end

  describe 'authorization' do
    it 'authorizes risk management access' do
      expect(controller).to receive(:authorize).with(project, :manage_risks?)
      get :dashboard, params: { project_id: project.id }
    end
  end

  describe 'private methods' do
    it 'responds to risk calculation methods' do
      expect(controller).to respond_to(:calculate_risk_score, true)
      expect(controller).to respond_to(:determine_severity, true)
      expect(controller).to respond_to(:generate_risk_alerts, true)
    end

    it 'responds to detection methods' do
      expect(controller).to respond_to(:detect_emerging_risks, true)
      expect(controller).to respond_to(:project_delay_risk?, true)
      expect(controller).to respond_to(:budget_overrun_risk?, true)
    end
  end
end