require 'rails_helper'

RSpec.describe Immo::Promo::CoordinationController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  
  before do
    sign_in user
    allow(controller).to receive(:current_organization).and_return(organization)
  end

  describe 'GET #dashboard' do
    context 'when user has access' do
      before do
        create_list(:immo_promo_stakeholder, 5, project: project)
        create_list(:immo_promo_task, 10, project: project)
      end

      it 'returns http success' do
        get :dashboard, params: { project_id: project.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns project' do
        get :dashboard, params: { project_id: project.id }
        expect(assigns(:project)).to eq(project)
      end

      it 'loads coordination service data' do
        get :dashboard, params: { project_id: project.id }
        
        expect(assigns(:active_interventions)).to be_present
        expect(assigns(:upcoming_interventions)).to be_present
        expect(assigns(:conflicts)).to be_present
        expect(assigns(:certifications_status)).to be_present
        expect(assigns(:performance_metrics)).to be_present
      end

      it 'renders dashboard template' do
        get :dashboard, params: { project_id: project.id }
        expect(response).to render_template('dashboard')
      end
    end

    context 'when user lacks permissions' do
      let(:other_org) { create(:organization) }
      let(:other_project) { create(:immo_promo_project, organization: other_org) }

      it 'raises not found error' do
        expect {
          get :dashboard, params: { project_id: other_project.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET #interventions' do
    let!(:stakeholders) { create_list(:immo_promo_stakeholder, 3, project: project) }
    let!(:tasks) { create_list(:immo_promo_task, 5, project: project, assigned_to: stakeholders.sample) }

    it 'returns http success' do
      get :interventions, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads interventions with filters' do
      get :interventions, params: { 
        project_id: project.id,
        filters: { status: 'active', stakeholder: stakeholders.first.id }
      }
      
      expect(assigns(:interventions)).to be_present
      expect(assigns(:filters)).to include('status' => 'active')
    end

    it 'groups interventions by week' do
      get :interventions, params: { project_id: project.id }
      expect(assigns(:interventions_by_week)).to be_a(Hash)
    end
  end

  describe 'GET #timeline' do
    before do
      create_list(:immo_promo_phase, 3, project: project)
      create_list(:immo_promo_task, 10, project: project)
    end

    it 'returns http success' do
      get :timeline, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads timeline data' do
      get :timeline, params: { project_id: project.id }
      
      expect(assigns(:timeline_data)).to be_present
      expect(assigns(:critical_path)).to be_present
      expect(assigns(:dependencies)).to be_present
    end
  end

  describe 'GET #performance' do
    let!(:stakeholders) { create_list(:immo_promo_stakeholder, 3, project: project) }

    it 'returns http success' do
      get :performance, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'calculates performance metrics' do
      get :performance, params: { project_id: project.id }
      
      expect(assigns(:stakeholder_performance)).to be_present
      expect(assigns(:team_metrics)).to be_present
      expect(assigns(:quality_indicators)).to be_present
    end

    it 'supports time period filtering' do
      get :performance, params: { 
        project_id: project.id,
        period: 'last_month'
      }
      
      expect(assigns(:period)).to eq('last_month')
    end
  end

  describe 'GET #certifications' do
    let!(:stakeholders) { create_list(:immo_promo_stakeholder, 3, project: project) }
    let!(:certifications) { 
      stakeholders.map do |s|
        create(:immo_promo_certification, stakeholder: s)
      end
    }

    it 'returns http success' do
      get :certifications, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads certification data' do
      get :certifications, params: { project_id: project.id }
      
      expect(assigns(:certifications_by_type)).to be_present
      expect(assigns(:expiring_certifications)).to be_present
      expect(assigns(:compliance_status)).to be_present
    end
  end

  describe 'POST #conflicts_resolution' do
    let(:conflict_data) {
      {
        conflicts: [
          {
            stakeholder1_id: create(:immo_promo_stakeholder, project: project).id,
            stakeholder2_id: create(:immo_promo_stakeholder, project: project).id,
            date: Date.tomorrow,
            type: 'resource_conflict'
          }
        ]
      }
    }

    context 'when viewing conflicts' do
      it 'detects conflicts' do
        get :conflicts_resolution, params: { project_id: project.id }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:detected_conflicts)).to be_present
      end
    end

    context 'when resolving conflicts' do
      it 'processes resolution' do
        post :conflicts_resolution, params: { 
          project_id: project.id,
          resolution: {
            conflict_id: 'conflict_1',
            action: 'reassign',
            new_stakeholder_id: create(:immo_promo_stakeholder, project: project).id
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_coordination_conflicts_path(project))
        expect(flash[:success]).to be_present
      end
    end
  end

  describe 'POST #assign_stakeholder' do
    let(:task) { create(:immo_promo_task, project: project) }
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }

    it 'assigns stakeholder to task' do
      post :assign_stakeholder, params: {
        project_id: project.id,
        task_id: task.id,
        stakeholder_id: stakeholder.id
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_coordination_interventions_path(project))
      expect(task.reload.assigned_to).to eq(stakeholder)
      expect(flash[:success]).to be_present
    end

    it 'handles invalid assignment' do
      post :assign_stakeholder, params: {
        project_id: project.id,
        task_id: task.id,
        stakeholder_id: 'invalid'
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_coordination_interventions_path(project))
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #send_coordination_alert' do
    let(:stakeholders) { create_list(:immo_promo_stakeholder, 2, project: project) }

    it 'sends alert successfully' do
      post :send_coordination_alert, params: {
        project_id: project.id,
        alert: {
          type: 'urgent_intervention',
          message: 'Intervention urgente requise',
          stakeholder_ids: stakeholders.map(&:id)
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_coordination_dashboard_path(project))
      expect(flash[:success]).to match(/Alerte envoyée/)
    end
  end

  describe 'GET #export_report' do
    it 'generates PDF report' do
      get :export_report, params: { 
        project_id: project.id,
        format: :pdf
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
    end

    it 'generates Excel report' do
      get :export_report, params: {
        project_id: project.id,
        format: :xlsx
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/spreadsheetml/)
    end

    it 'includes date range in report' do
      get :export_report, params: {
        project_id: project.id,
        format: :pdf,
        start_date: '2024-01-01',
        end_date: '2024-12-31'
      }
      
      expect(assigns(:report_data)[:period]).to be_present
    end
  end

  describe 'JSON responses' do
    it 'returns JSON for dashboard' do
      get :dashboard, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('active_interventions')
      expect(json).to have_key('performance_metrics')
    end

    it 'returns JSON for timeline' do
      get :timeline, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('timeline')
      expect(json).to have_key('critical_path')
    end
  end
end