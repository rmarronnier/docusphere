require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflowController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:permit_tracker) { instance_double('Immo::Promo::PermitTrackerService') }

  before do
    sign_in user
    allow(Immo::Promo::PermitTrackerService).to receive(:new).and_return(permit_tracker)
    allow(permit_tracker).to receive(:track_permit_status).and_return({})
    allow(permit_tracker).to receive(:critical_permits_status).and_return([])
    allow(permit_tracker).to receive(:compliance_check).and_return({})
    allow(permit_tracker).to receive(:identify_bottlenecks).and_return([])
    allow(permit_tracker).to receive(:suggest_next_actions).and_return([])
  end

  describe 'GET #dashboard' do
    it 'returns a success response' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'initializes permit tracker and assigns variables' do
      get :dashboard, params: { project_id: project.id }
      expect(assigns(:permit_tracker)).to eq(permit_tracker)
      expect(assigns(:permit_status)).to be_present
      expect(assigns(:critical_permits)).to be_present
      expect(assigns(:compliance_check)).to be_present
      expect(assigns(:bottlenecks)).to be_present
      expect(assigns(:next_actions)).to be_present
    end

    it 'responds to JSON format' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #workflow_guide' do
    it 'returns a success response' do
      get :workflow_guide, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns workflow data' do
      get :workflow_guide, params: { project_id: project.id }
      expect(assigns(:workflow_steps)).to be_present
      expect(assigns(:current_step)).to be_present
      expect(assigns(:completed_steps)).to be_present
      expect(assigns(:next_required_actions)).to be_present
    end
  end

  describe 'GET #compliance_checklist' do
    before do
      allow(permit_tracker).to receive(:compliance_check).and_return({})
    end

    it 'returns a success response' do
      get :compliance_checklist, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns compliance data' do
      get :compliance_checklist, params: { project_id: project.id }
      expect(assigns(:compliance_data)).to be_present
      expect(assigns(:regulatory_requirements)).to be_present
      expect(assigns(:missing_documents)).to be_present
      expect(assigns(:condition_compliance)).to be_present
    end
  end

  describe 'GET #timeline_tracker' do
    before do
      allow(permit_tracker).to receive(:generate_permit_timeline).and_return({})
      allow(permit_tracker).to receive(:calculate_processing_times).and_return({})
    end

    it 'returns a success response' do
      get :timeline_tracker, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns timeline data' do
      get :timeline_tracker, params: { project_id: project.id }
      expect(assigns(:timeline_data)).to be_present
      expect(assigns(:processing_times)).to be_present
      expect(assigns(:deadlines)).to be_present
      expect(assigns(:milestones)).to be_present
    end
  end

  describe 'GET #critical_path' do
    it 'returns a success response' do
      get :critical_path, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns critical path data' do
      get :critical_path, params: { project_id: project.id }
      expect(assigns(:critical_permits)).to be_present
      expect(assigns(:dependencies)).to be_present
      expect(assigns(:blocking_permits)).to be_present
      expect(assigns(:construction_readiness)).to be_present
    end
  end

  describe 'POST #submit_permit' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'submits permit when allowed' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_submitted?).and_return(true)
      allow(controller).to receive(:submit_permit_application).and_return({ success: true })
      
      post :submit_permit, params: { project_id: project.id, permit_id: permit.id }
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permit_workflow/dashboard")
      expect(flash[:success]).to be_present
    end

    it 'shows error when permit cannot be submitted' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_submitted?).and_return(false)
      
      post :submit_permit, params: { project_id: project.id, permit_id: permit.id }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #track_response' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'updates permit status when response available' do
      allow(controller).to receive(:check_permit_status_with_administration).and_return({
        status_changed: true,
        new_status: 'approved',
        response_date: Date.current,
        reference: 'REF123'
      })
      
      post :track_response, params: { project_id: project.id, permit_id: permit.id }
      
      expect(flash[:success]).to be_present
    end

    it 'shows info when no update available' do
      allow(controller).to receive(:check_permit_status_with_administration).and_return({
        status_changed: false
      })
      
      post :track_response, params: { project_id: project.id, permit_id: permit.id }
      
      expect(flash[:info]).to be_present
    end
  end

  describe 'POST #extend_permit' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'extends permit when allowed' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_extended?).and_return(true)
      allow(controller).to receive(:request_permit_extension).and_return({ success: true })
      
      post :extend_permit, params: {
        project_id: project.id,
        permit_id: permit.id,
        extension_months: '12',
        justification: 'Project delay'
      }
      
      expect(flash[:success]).to be_present
    end

    it 'shows error when permit cannot be extended' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_extended?).and_return(false)
      
      post :extend_permit, params: { project_id: project.id, permit_id: permit.id }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST #validate_condition' do
    let(:permit) { create(:immo_promo_permit, project: project) }
    let(:condition) { create(:immo_promo_permit_condition, permit: permit) }

    it 'validates condition successfully' do
      allow(controller).to receive(:validate_permit_condition).and_return({
        valid: true,
        errors: []
      })
      
      post :validate_condition, params: {
        project_id: project.id,
        permit_id: permit.id,
        condition_id: condition.id,
        validation_data: { test: 'data' },
        validation_notes: 'Test validation'
      }
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permit_workflow/compliance_checklist")
      expect(flash[:success]).to be_present
    end

    it 'shows error when validation fails' do
      allow(controller).to receive(:validate_permit_condition).and_return({
        valid: false,
        errors: ['Missing documentation']
      })
      
      post :validate_condition, params: {
        project_id: project.id,
        permit_id: permit.id,
        condition_id: condition.id,
        validation_data: {}
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'GET #generate_submission_package' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'generates PDF submission package' do
      allow(controller).to receive(:compile_submission_package).and_return({})
      
      get :generate_submission_package, params: {
        project_id: project.id,
        permit_id: permit.id
      }, format: :pdf
      
      expect(response).to be_successful
      expect(response.content_type).to include('application/pdf')
    end

    it 'generates ZIP submission package' do
      allow(controller).to receive(:compile_submission_package).and_return({})
      allow(controller).to receive(:generate_submission_zip).and_return('/tmp/test.zip')
      
      get :generate_submission_package, params: {
        project_id: project.id,
        permit_id: permit.id
      }, format: :zip
      
      expect(response).to be_successful
    end
  end

  describe 'POST #alert_administration' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'sends delay inquiry successfully' do
      allow(controller).to receive(:send_delay_inquiry).and_return({ success: true })
      
      post :alert_administration, params: {
        project_id: project.id,
        permit_id: permit.id,
        alert_type: 'delay_inquiry'
      }
      
      expect(flash[:success]).to be_present
    end

    it 'sends urgent request successfully' do
      allow(controller).to receive(:send_urgent_request).and_return({ success: true })
      
      post :alert_administration, params: {
        project_id: project.id,
        permit_id: permit.id,
        alert_type: 'urgent_request',
        urgency_justification: 'Critical deadline'
      }
      
      expect(flash[:success]).to be_present
    end

    it 'handles unknown alert type' do
      post :alert_administration, params: {
        project_id: project.id,
        permit_id: permit.id,
        alert_type: 'unknown_type'
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'GET #export_report' do
    before do
      allow(permit_tracker).to receive(:generate_permit_report).and_return({})
    end

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
    it 'authorizes permit access' do
      expect(controller).to receive(:authorize).with(project, :manage_permits?)
      get :dashboard, params: { project_id: project.id }
    end
  end

  describe 'private methods' do
    it 'responds to workflow generation methods' do
      expect(controller).to respond_to(:generate_workflow_for_project_type, true)
      expect(controller).to respond_to(:determine_current_workflow_step, true)
      expect(controller).to respond_to(:get_regulatory_requirements_for_project, true)
    end
  end
end