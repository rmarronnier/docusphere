require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoringController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  
  before do
    sign_in user
    allow(controller).to receive(:current_organization).and_return(organization)
  end

  describe 'GET #dashboard' do
    let!(:risks) do
      [
        create(:immo_promo_risk, project: project, severity: 'critical', status: 'active'),
        create(:immo_promo_risk, project: project, severity: 'high', status: 'active'),
        create(:immo_promo_risk, project: project, severity: 'medium', status: 'active'),
        create(:immo_promo_risk, project: project, severity: 'low', status: 'mitigated')
      ]
    end

    it 'returns http success' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads risk overview' do
      get :dashboard, params: { project_id: project.id }
      
      overview = assigns(:risk_overview)
      expect(overview).to be_present
      expect(overview[:total_risks]).to eq(4)
      expect(overview[:by_severity]['critical']).to eq(1)
    end

    it 'generates risk matrix' do
      get :dashboard, params: { project_id: project.id }
      
      matrix = assigns(:risk_matrix)
      expect(matrix).to be_present
      expect(matrix).to be_a(Hash)
    end

    it 'loads mitigation status' do
      get :dashboard, params: { project_id: project.id }
      
      mitigation = assigns(:mitigation_status)
      expect(mitigation).to include(:total_actions, :completed, :in_progress, :overdue)
    end

    it 'generates alerts for critical risks' do
      get :dashboard, params: { project_id: project.id }
      
      alerts = assigns(:alerts)
      expect(alerts).to be_present
      expect(alerts.first[:severity]).to eq('critical')
    end
  end

  describe 'GET #risk_register' do
    let!(:risks) { create_list(:immo_promo_risk, 10, project: project) }

    it 'returns http success' do
      get :risk_register, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads all project risks' do
      get :risk_register, params: { project_id: project.id }
      
      expect(assigns(:risks).count).to eq(10)
    end

    it 'filters risks by category' do
      technical_risk = create(:immo_promo_risk, project: project, category: 'technical')
      financial_risk = create(:immo_promo_risk, project: project, category: 'financial')
      
      get :risk_register, params: {
        project_id: project.id,
        filters: { category: 'technical' }
      }
      
      filtered_risks = assigns(:risks)
      expect(filtered_risks).to include(technical_risk)
      expect(filtered_risks).not_to include(financial_risk)
    end

    it 'filters risks by severity' do
      get :risk_register, params: {
        project_id: project.id,
        filters: { severity: 'high' }
      }
      
      expect(assigns(:risks)).to be_present
    end

    it 'filters risks by probability and impact' do
      high_prob_risk = create(:immo_promo_risk, project: project, probability: 'high', impact: 'major')
      
      get :risk_register, params: {
        project_id: project.id,
        filters: { probability: 'high', impact: 'major' }
      }
      
      expect(assigns(:risks)).to include(high_prob_risk)
    end
  end

  describe 'GET #alert_center' do
    it 'returns http success' do
      get :alert_center, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads active alerts' do
      get :alert_center, params: { project_id: project.id }
      
      expect(assigns(:active_alerts)).to be_present
      expect(assigns(:alert_history)).to be_present
      expect(assigns(:alert_configurations)).to be_present
    end

    it 'shows notification channels' do
      get :alert_center, params: { project_id: project.id }
      
      channels = assigns(:notification_channels)
      expect(channels).to include('email', 'sms', 'dashboard')
    end
  end

  describe 'GET #early_warning_system' do
    it 'returns http success' do
      get :early_warning_system, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'calculates warning indicators' do
      get :early_warning_system, params: { project_id: project.id }
      
      indicators = assigns(:warning_indicators)
      expect(indicators).to be_present
    end

    it 'analyzes trends' do
      get :early_warning_system, params: { project_id: project.id }
      
      trends = assigns(:trend_analysis)
      expect(trends).to be_present
    end

    it 'generates predictive alerts' do
      get :early_warning_system, params: { project_id: project.id }
      
      predictive_alerts = assigns(:predictive_alerts)
      expect(predictive_alerts).to be_present
    end
  end

  describe 'POST #create_risk' do
    context 'with valid params' do
      let(:risk_params) do
        {
          title: 'Retard livraison matériaux',
          description: 'Risque de retard dans la livraison des matériaux de construction',
          category: 'schedule',
          probability: 'medium',
          impact: 'major',
          risk_owner_id: create(:immo_promo_stakeholder, project: project).id,
          detection_date: Date.current,
          target_resolution_date: 2.months.from_now
        }
      end

      it 'creates a new risk' do
        expect {
          post :create_risk, params: {
            project_id: project.id,
            risk: risk_params
          }
        }.to change(project.risks, :count).by(1)
        
        expect(response).to redirect_to(immo_promo_engine.project_risk_monitoring_risk_register_path(project))
        expect(flash[:success]).to be_present
      end

      it 'calculates risk score automatically' do
        post :create_risk, params: {
          project_id: project.id,
          risk: risk_params
        }
        
        risk = project.risks.last
        expect(risk.risk_score).to be_present
        expect(risk.severity).to eq('high') # medium * major = high
      end

      it 'creates initial assessment' do
        post :create_risk, params: {
          project_id: project.id,
          risk: risk_params
        }
        
        risk = project.risks.last
        expect(risk.risk_assessments.count).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'does not create risk without title' do
        expect {
          post :create_risk, params: {
            project_id: project.id,
            risk: { description: 'Test' }
          }
        }.not_to change(project.risks, :count)
        
        expect(flash[:error]).to be_present
      end
    end
  end

  describe 'PATCH #update_risk_assessment' do
    let(:risk) { create(:immo_promo_risk, project: project, probability: 'low', impact: 'minor') }

    it 'updates risk assessment' do
      patch :update_risk_assessment, params: {
        project_id: project.id,
        risk_id: risk.id,
        assessment: {
          probability: 'high',
          impact: 'major',
          notes: 'Situation has deteriorated',
          reassessment_reason: 'New information received'
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_risk_monitoring_risk_register_path(project))
      expect(risk.reload.probability).to eq('high')
      expect(risk.impact).to eq('major')
      expect(flash[:success]).to be_present
    end

    it 'triggers escalation for critical risks' do
      patch :update_risk_assessment, params: {
        project_id: project.id,
        risk_id: risk.id,
        assessment: {
          probability: 'very_high',
          impact: 'catastrophic'
        }
      }
      
      expect(risk.reload.severity).to eq('critical')
      # Should create escalation record
    end
  end

  describe 'POST #create_mitigation_action' do
    let(:risk) { create(:immo_promo_risk, project: project) }
    let(:responsible) { create(:immo_promo_stakeholder, project: project) }

    it 'creates mitigation action' do
      post :create_mitigation_action, params: {
        project_id: project.id,
        risk_id: risk.id,
        action: {
          action_type: 'preventive',
          description: 'Diversifier les fournisseurs',
          responsible_id: responsible.id,
          due_date: 1.month.from_now,
          cost_estimate: 10000,
          effectiveness_estimate: 80
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_risk_monitoring_risk_register_path(project))
      expect(risk.mitigation_actions.count).to eq(1)
      expect(flash[:success]).to be_present
    end

    it 'updates risk mitigation status' do
      post :create_mitigation_action, params: {
        project_id: project.id,
        risk_id: risk.id,
        action: {
          action_type: 'corrective',
          description: 'Action corrective',
          responsible_id: responsible.id,
          due_date: 1.week.from_now
        }
      }
      
      expect(risk.reload.mitigation_status).to eq('mitigation_in_progress')
    end
  end

  describe 'POST #configure_alert' do
    it 'configures risk alert' do
      post :configure_alert, params: {
        project_id: project.id,
        alert: {
          alert_type: 'new_critical_risk',
          threshold_value: 1,
          comparison_operator: 'greater_than',
          notification_channels: ['email', 'sms'],
          recipients: ['pm@example.com', 'risk@example.com'],
          active: true
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_risk_monitoring_alert_center_path(project))
      expect(flash[:success]).to be_present
    end
  end

  describe 'POST #acknowledge_alert' do
    let(:alert) { create(:alert, project: project) }

    it 'acknowledges alert' do
      post :acknowledge_alert, params: {
        project_id: project.id,
        alert_id: alert.id
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_risk_monitoring_alert_center_path(project))
      expect(alert.reload).to be_acknowledged
      expect(flash[:success]).to be_present
    end
  end

  describe 'GET #risk_report' do
    let!(:risks) { create_list(:immo_promo_risk, 5, project: project) }

    it 'generates PDF risk report' do
      get :risk_report, params: {
        project_id: project.id,
        format: :pdf
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
    end

    it 'generates Excel risk report' do
      get :risk_report, params: {
        project_id: project.id,
        format: :xlsx
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/spreadsheetml/)
    end

    it 'includes comprehensive analysis' do
      get :risk_report, params: {
        project_id: project.id,
        format: :pdf
      }
      
      report_data = assigns(:report_data)
      expect(report_data).to include(
        :executive_summary,
        :risk_overview,
        :risk_matrix,
        :active_risks,
        :mitigation_status,
        :trend_analysis,
        :recommendations
      )
    end
  end

  describe 'GET #risk_matrix_export' do
    let!(:risks) { create_list(:immo_promo_risk, 10, project: project) }

    it 'exports risk matrix as JSON' do
      get :risk_matrix_export, params: {
        project_id: project.id,
        format: :json
      }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_a(Hash)
    end

    it 'exports risk matrix as SVG' do
      get :risk_matrix_export, params: {
        project_id: project.id,
        format: :svg
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('image/svg+xml')
    end
  end

  describe 'Edge cases and validations' do
    it 'handles project without risks' do
      get :dashboard, params: { project_id: project.id }
      
      expect(response).to have_http_status(:success)
      expect(assigns(:risk_overview)[:total_risks]).to eq(0)
    end

    it 'handles invalid risk owner' do
      post :create_risk, params: {
        project_id: project.id,
        risk: {
          title: 'Test Risk',
          risk_owner_id: 'invalid'
        }
      }
      
      expect(flash[:error]).to be_present
    end

    it 'prevents unauthorized access' do
      other_project = create(:immo_promo_project, organization: create(:organization))
      
      expect {
        get :dashboard, params: { project_id: other_project.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'JSON API responses' do
    it 'returns risk dashboard as JSON' do
      get :dashboard, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('risk_overview', 'risk_matrix', 'mitigation_status', 'alerts')
    end

    it 'returns risk matrix as JSON' do
      get :risk_matrix_export, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_a(Hash)
    end
  end
end