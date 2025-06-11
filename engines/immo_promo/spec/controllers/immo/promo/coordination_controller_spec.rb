require 'rails_helper'

RSpec.describe Immo::Promo::CoordinationController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:coordinator_service) { instance_double('Immo::Promo::StakeholderCoordinatorService') }

  before do
    sign_in user
    allow(Immo::Promo::StakeholderCoordinatorService).to receive(:new).and_return(coordinator_service)
    allow(coordinator_service).to receive(:coordinate_interventions).and_return({
      current_interventions: [],
      upcoming_interventions: [],
      conflicts: [],
      recommendations: []
    })
    allow(coordinator_service).to receive(:check_certifications).and_return([])
    allow(coordinator_service).to receive(:generate_coordination_report).and_return({
      stakeholder_performance: [],
      intervention_timeline: []
    })
  end

  describe 'GET #dashboard' do
    it 'returns a success response' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'initializes coordinator service and assigns variables' do
      get :dashboard, params: { project_id: project.id }
      expect(assigns(:coordinator)).to eq(coordinator_service)
      expect(assigns(:coordination_data)).to be_present
      expect(assigns(:certifications_status)).to be_present
      expect(assigns(:coordination_report)).to be_present
    end

    it 'responds to JSON format' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #interventions' do
    it 'returns a success response' do
      get :interventions, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns intervention data' do
      get :interventions, params: { project_id: project.id }
      expect(assigns(:current_interventions)).to be_present
      expect(assigns(:upcoming_interventions)).to be_present
      expect(assigns(:conflicts)).to be_present
      expect(assigns(:recommendations)).to be_present
    end
  end

  describe 'GET #certifications' do
    before do
      allow(coordinator_service).to receive(:check_certifications).and_return([
        { status: 'critical', stakeholder: 'Test Critical' },
        { status: 'warning', stakeholder: 'Test Warning' },
        { status: 'valid', stakeholder: 'Test Valid' }
      ])
    end

    it 'returns a success response' do
      get :certifications, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'groups stakeholders by certification status' do
      get :certifications, params: { project_id: project.id }
      expect(assigns(:critical_stakeholders)).to have(1).item
      expect(assigns(:warning_stakeholders)).to have(1).item
      expect(assigns(:valid_stakeholders)).to have(1).item
    end
  end

  describe 'GET #performance' do
    before do
      allow(coordinator_service).to receive(:generate_coordination_report).and_return({
        stakeholder_performance: [
          { name: 'Stakeholder 1', performance_score: 85 },
          { name: 'Stakeholder 2', performance_score: 65 },
          { name: 'Stakeholder 3', performance_score: 95 }
        ]
      })
    end

    it 'returns a success response' do
      get :performance, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'identifies top and poor performers' do
      get :performance, params: { project_id: project.id }
      expect(assigns(:top_performers)).to have(3).items
      expect(assigns(:poor_performers)).to have(1).item
    end
  end

  describe 'GET #timeline' do
    before do
      allow(coordinator_service).to receive(:generate_coordination_report).and_return({
        intervention_timeline: [
          { phase: 'Phase 1', event: 'Event 1' },
          { phase: 'Phase 1', event: 'Event 2' },
          { phase: 'Phase 2', event: 'Event 3' }
        ]
      })
    end

    it 'returns a success response' do
      get :timeline, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'groups timeline by phase' do
      get :timeline, params: { project_id: project.id }
      expect(assigns(:timeline_by_phase)).to have_key('Phase 1')
      expect(assigns(:timeline_by_phase)).to have_key('Phase 2')
      expect(assigns(:timeline_by_phase)['Phase 1']).to have(2).items
    end
  end

  describe 'GET #conflicts_resolution' do
    it 'returns a success response' do
      get :conflicts_resolution, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns conflicts and recommendations' do
      get :conflicts_resolution, params: { project_id: project.id }
      expect(assigns(:conflicts)).to be_present
      expect(assigns(:recommendations)).to be_present
    end
  end

  describe 'POST #conflicts_resolution' do
    it 'handles conflict resolution' do
      expect(controller).to receive(:handle_conflict_resolution)
      
      post :conflicts_resolution, params: { 
        project_id: project.id,
        resolution_actions: {
          '1' => { type: 'reassign_task', task_id: '1', new_assignee_id: '2' }
        }
      }
      
      expect(response).to be_successful
    end
  end

  describe 'PATCH #assign_stakeholder' do
    let(:task) { create(:immo_promo_task, project: project) }
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }

    it 'assigns stakeholder to task successfully' do
      patch :assign_stakeholder, params: {
        project_id: project.id,
        task_id: task.id,
        stakeholder_id: stakeholder.id
      }
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/coordination/conflicts_resolution")
      expect(flash[:success]).to be_present
    end

    it 'handles assignment failure' do
      allow_any_instance_of(Immo::Promo::Task).to receive(:update).and_return(false)
      
      patch :assign_stakeholder, params: {
        project_id: project.id,
        task_id: task.id,
        stakeholder_id: stakeholder.id
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #send_coordination_alert' do
    let(:stakeholder1) { create(:immo_promo_stakeholder, project: project) }
    let(:stakeholder2) { create(:immo_promo_stakeholder, project: project) }

    it 'sends alerts to stakeholders successfully' do
      post :send_coordination_alert, params: {
        project_id: project.id,
        stakeholder_ids: [stakeholder1.id, stakeholder2.id],
        message: 'Test alert message',
        alert_type: 'deadline'
      }
      
      expect(flash[:success]).to include('2 intervenants')
    end

    it 'shows error when no stakeholders selected' do
      post :send_coordination_alert, params: {
        project_id: project.id,
        stakeholder_ids: [],
        message: 'Test message'
      }
      
      expect(flash[:error]).to be_present
    end

    it 'shows error when no message provided' do
      post :send_coordination_alert, params: {
        project_id: project.id,
        stakeholder_ids: [stakeholder1.id],
        message: ''
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'GET #export_report' do
    it 'exports report as PDF' do
      get :export_report, params: { project_id: project.id }, format: :pdf
      expect(response).to be_successful
      expect(response.content_type).to include('application/pdf')
    end

    it 'exports report as XLSX' do
      get :export_report, params: { project_id: project.id }, format: :xlsx
      expect(response).to be_successful
    end
  end

  describe 'authorization' do
    it 'authorizes coordination access' do
      expect(controller).to receive(:authorize).with(project, :coordinate?)
      get :dashboard, params: { project_id: project.id }
    end
  end

  describe 'private methods' do
    describe '#handle_conflict_resolution' do
      it 'responds to handle_conflict_resolution' do
        expect(controller).to respond_to(:handle_conflict_resolution, true)
      end
    end

    describe '#send_alerts_to_stakeholders' do
      it 'responds to send_alerts_to_stakeholders' do
        expect(controller).to respond_to(:send_alerts_to_stakeholders, true)
      end
    end
  end
end