require 'rails_helper'

RSpec.describe Immo::Promo::PermitDashboardController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_type: 'residential') }
  let(:permit_tracker) { instance_double('Immo::Promo::PermitTrackerService') }

  before do
    sign_in user
    allow(controller).to receive(:policy_scope).and_return(Immo::Promo::Project.where(id: project.id))
    allow(controller).to receive(:authorize).and_return(true)
    allow(Immo::Promo::PermitTrackerService).to receive(:new).and_return(permit_tracker)
    allow(permit_tracker).to receive(:track_permit_status).and_return({})
    allow(permit_tracker).to receive(:critical_permits_status).and_return([])
    allow(permit_tracker).to receive(:compliance_check).and_return({})
    allow(permit_tracker).to receive(:identify_bottlenecks).and_return([])
    allow(permit_tracker).to receive(:suggest_next_actions).and_return([])
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns permit dashboard data' do
      get :show, params: { project_id: project.id }, format: :json
      expect(assigns(:permit_status)).to be_present
      expect(assigns(:critical_permits)).to be_present
      expect(assigns(:compliance_check)).to be_present
      expect(assigns(:bottlenecks)).to be_present
      expect(assigns(:next_actions)).to be_present
    end

    it 'responds to JSON format' do
      get :show, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #workflow_guide' do
    it 'returns a success response' do
      get :workflow_guide, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'generates workflow for residential project' do
      get :workflow_guide, params: { project_id: project.id }, format: :json
      expect(assigns(:workflow_steps)).to be_present
      expect(assigns(:workflow_steps).first[:name]).to eq('Déclaration préalable')
    end

    it 'assigns current step and completed steps' do
      get :workflow_guide, params: { project_id: project.id }, format: :json
      expect(assigns(:current_step)).to be_present
      expect(assigns(:completed_steps)).to be_present
    end
  end

  describe 'GET #compliance_checklist' do
    it 'returns a success response' do
      get :compliance_checklist, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns compliance data' do
      get :compliance_checklist, params: { project_id: project.id }, format: :json
      expect(assigns(:compliance_data)).to be_present
      expect(assigns(:regulatory_requirements)).to be_present
      expect(assigns(:missing_documents)).to be_present
      expect(assigns(:condition_compliance)).to be_present
    end

    it 'identifies missing documents' do
      get :compliance_checklist, params: { project_id: project.id }, format: :json
      missing_docs = assigns(:missing_documents)
      expect(missing_docs).to include('plan_situation')
      expect(missing_docs).to include('plan_masse')
    end
  end

  describe 'authorization' do
    it 'authorizes permit access' do
      expect(controller).to receive(:authorize).with(project, :manage_permits?)
      get :show, params: { project_id: project.id }, format: :json
    end
  end

  describe 'private methods' do
    describe '#generate_workflow_for_project_type' do
      it 'generates residential workflow' do
        workflow = controller.send(:generate_workflow_for_project_type, 'residential')
        expect(workflow).to be_an(Array)
        expect(workflow.first[:name]).to eq('Déclaration préalable')
      end

      it 'generates commercial workflow' do
        workflow = controller.send(:generate_workflow_for_project_type, 'commercial')
        expect(workflow).to be_an(Array)
        expect(workflow.first[:name]).to eq('Autorisation commerciale')
      end

      it 'generates mixed workflow' do
        workflow = controller.send(:generate_workflow_for_project_type, 'mixed')
        expect(workflow).to be_an(Array)
        expect(workflow.length).to be > 5
      end
    end

    describe '#get_regulatory_requirements_for_project' do
      it 'returns regulatory requirements' do
        requirements = controller.send(:get_regulatory_requirements_for_project)
        expect(requirements).to have_key(:urbanisme)
        expect(requirements).to have_key(:environnement)
        expect(requirements).to have_key(:securite)
        expect(requirements).to have_key(:accessibilite)
      end
    end

    describe '#environmental_requirements' do
      it 'includes environmental impact study for large projects' do
        allow(project).to receive(:surface_area).and_return(15000)
        requirements = controller.send(:environmental_requirements)
        expect(requirements).to include('Étude d\'impact environnemental obligatoire')
      end

      it 'includes ICPE authorization for industrial projects' do
        allow(project).to receive(:project_type).and_return('industrial')
        requirements = controller.send(:environmental_requirements)
        expect(requirements).to include('Autorisation ICPE')
      end
    end

    describe '#get_required_documents_for_project_type' do
      it 'returns base documents for residential project' do
        docs = controller.send(:get_required_documents_for_project_type)
        expect(docs).to include('plan_situation')
        expect(docs).to include('plan_masse')
        expect(docs).to include('plan_facades')
      end

      it 'includes additional documents for commercial project' do
        allow(project).to receive(:project_type).and_return('commercial')
        docs = controller.send(:get_required_documents_for_project_type)
        expect(docs).to include('etude_impact_commercial')
        expect(docs).to include('plan_amenagement_paysager')
      end
    end

    describe '#calculate_condition_compliance_rate' do
      let(:validated_condition) { double('PermitCondition', status: 'validated') }
      let(:pending_condition) { double('PermitCondition', status: 'pending') }

      it 'returns 100% for validated conditions' do
        rate = controller.send(:calculate_condition_compliance_rate, validated_condition)
        expect(rate).to eq(100)
      end

      it 'returns 0% for pending conditions' do
        rate = controller.send(:calculate_condition_compliance_rate, pending_condition)
        expect(rate).to eq(0)
      end
    end
  end
end