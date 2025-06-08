require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflowController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  
  before do
    sign_in user
    allow(controller).to receive(:current_organization).and_return(organization)
  end

  describe 'GET #dashboard' do
    let!(:permits) { create_list(:immo_promo_permit, 3, project: project) }

    it 'returns http success' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads permit workflow data' do
      get :dashboard, params: { project_id: project.id }
      
      expect(assigns(:permits)).to match_array(permits)
      expect(assigns(:workflow_status)).to be_present
      expect(assigns(:upcoming_deadlines)).to be_present
      expect(assigns(:compliance_score)).to be_present
    end

    it 'calculates compliance metrics' do
      get :dashboard, params: { project_id: project.id }
      
      compliance_score = assigns(:compliance_score)
      expect(compliance_score).to be_a(Numeric)
      expect(compliance_score).to be_between(0, 100)
    end
  end

  describe 'GET #workflow_guide' do
    it 'returns workflow for residential project' do
      project.update(project_type: 'residential')
      get :workflow_guide, params: { project_id: project.id }
      
      expect(response).to have_http_status(:success)
      expect(assigns(:workflow_steps)).to be_present
      expect(assigns(:current_step)).to be_present
    end

    it 'returns workflow for commercial project' do
      project.update(project_type: 'commercial')
      get :workflow_guide, params: { project_id: project.id }
      
      workflow_steps = assigns(:workflow_steps)
      expect(workflow_steps).to include(hash_including(id: 'environmental_impact'))
    end

    it 'adapts workflow based on project size' do
      project.update(total_area_sqm: 10000) # Large project
      get :workflow_guide, params: { project_id: project.id }
      
      workflow_steps = assigns(:workflow_steps)
      expect(workflow_steps.length).to be > 10 # More steps for larger projects
    end
  end

  describe 'GET #compliance_checklist' do
    let!(:permits) { create_list(:immo_promo_permit, 2, project: project) }
    let!(:conditions) { 
      permits.flat_map do |permit|
        create_list(:immo_promo_permit_condition, 3, permit: permit)
      end
    }

    it 'returns http success' do
      get :compliance_checklist, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'organizes checklist by category' do
      get :compliance_checklist, params: { project_id: project.id }
      
      checklist = assigns(:compliance_checklist)
      expect(checklist).to have_key(:administrative)
      expect(checklist).to have_key(:technical)
      expect(checklist).to have_key(:environmental)
    end

    it 'tracks completion status' do
      conditions.first.update(status: 'completed')
      get :compliance_checklist, params: { project_id: project.id }
      
      expect(assigns(:completion_percentage)).to be > 0
    end
  end

  describe 'GET #timeline_tracker' do
    let!(:permits) do
      [
        create(:immo_promo_permit, project: project, submission_date: 1.month.ago),
        create(:immo_promo_permit, project: project, submission_date: 2.weeks.from_now)
      ]
    end

    it 'returns http success' do
      get :timeline_tracker, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'creates timeline with milestones' do
      get :timeline_tracker, params: { project_id: project.id }
      
      timeline = assigns(:permit_timeline)
      expect(timeline).to be_present
      expect(timeline).to include(hash_including(:date, :event, :status))
    end

    it 'identifies delays' do
      permits.first.update(expected_response_date: 1.week.ago)
      get :timeline_tracker, params: { project_id: project.id }
      
      expect(assigns(:delays)).to be_present
      expect(assigns(:delays).first).to include(:permit, :days_delayed)
    end
  end

  describe 'GET #critical_path' do
    let!(:permits) { create_list(:immo_promo_permit, 4, project: project) }

    it 'returns http success' do
      get :critical_path, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'identifies critical permits' do
      get :critical_path, params: { project_id: project.id }
      
      critical_permits = assigns(:critical_permits)
      expect(critical_permits).to be_present
      expect(critical_permits.first).to respond_to(:impact_score)
    end

    it 'calculates path dependencies' do
      get :critical_path, params: { project_id: project.id }
      
      dependencies = assigns(:permit_dependencies)
      expect(dependencies).to be_a(Hash)
    end
  end

  describe 'POST #submit_permit' do
    let(:permit) { create(:immo_promo_permit, project: project, status: 'draft') }

    context 'with valid submission' do
      it 'submits permit successfully' do
        post :submit_permit, params: {
          project_id: project.id,
          permit_id: permit.id,
          submission: {
            submission_method: 'electronic',
            tracking_number: 'TRACK123',
            submitted_documents: ['plan.pdf', 'form.pdf']
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_permit_workflow_dashboard_path(project))
        expect(permit.reload.status).to eq('submitted')
        expect(flash[:success]).to be_present
      end
    end

    context 'with missing documents' do
      it 'prevents submission' do
        post :submit_permit, params: {
          project_id: project.id,
          permit_id: permit.id,
          submission: {
            submission_method: 'electronic'
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_permit_workflow_dashboard_path(project))
        expect(flash[:error]).to match(/Documents manquants/)
        expect(permit.reload.status).to eq('draft')
      end
    end
  end

  describe 'POST #track_response' do
    let(:permit) { create(:immo_promo_permit, project: project, status: 'submitted') }

    it 'updates permit response' do
      post :track_response, params: {
        project_id: project.id,
        permit_id: permit.id,
        response: {
          status: 'approved_with_conditions',
          response_date: Date.current,
          conditions: ['Condition 1', 'Condition 2'],
          validity_period: 24
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_permit_workflow_dashboard_path(project))
      expect(permit.reload.status).to eq('approved_with_conditions')
      expect(permit.permit_conditions.count).to eq(2)
    end
  end

  describe 'POST #extend_permit' do
    let(:permit) { 
      create(:immo_promo_permit, 
        project: project, 
        status: 'approved',
        validity_end_date: 1.month.from_now
      ) 
    }

    it 'extends permit validity' do
      post :extend_permit, params: {
        project_id: project.id,
        permit_id: permit.id,
        extension: {
          months: 6,
          reason: 'Project delays due to weather'
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_permit_workflow_timeline_tracker_path(project))
      expect(permit.reload.validity_end_date).to be > 6.months.from_now
      expect(flash[:success]).to be_present
    end
  end

  describe 'POST #validate_condition' do
    let(:permit) { create(:immo_promo_permit, project: project) }
    let(:condition) { create(:immo_promo_permit_condition, permit: permit, status: 'pending') }

    it 'validates condition with evidence' do
      post :validate_condition, params: {
        project_id: project.id,
        permit_id: permit.id,
        condition_id: condition.id,
        validation: {
          status: 'completed',
          evidence: 'Photos uploaded to folder XYZ',
          validated_by: user.name
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_permit_workflow_compliance_checklist_path(project))
      expect(condition.reload.status).to eq('completed')
      expect(flash[:success]).to be_present
    end
  end

  describe 'GET #generate_submission_package' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'generates PDF package' do
      get :generate_submission_package, params: {
        project_id: project.id,
        permit_id: permit.id,
        format: :pdf
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to match(/dossier_soumission/)
    end

    it 'includes all required documents' do
      get :generate_submission_package, params: {
        project_id: project.id,
        permit_id: permit.id,
        format: :pdf
      }
      
      # The PDF should contain all sections
      expect(assigns(:package_content)).to include(
        :cover_page,
        :forms,
        :plans,
        :technical_documents,
        :administrative_documents
      )
    end
  end

  describe 'POST #alert_administration' do
    let(:permit) { create(:immo_promo_permit, project: project, status: 'submitted') }

    it 'sends follow-up alert' do
      post :alert_administration, params: {
        project_id: project.id,
        alert: {
          permit_id: permit.id,
          type: 'follow_up',
          message: 'Relance pour dossier PC-2024-001'
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_permit_workflow_dashboard_path(project))
      expect(flash[:success]).to match(/Relance envoyée/)
    end
  end

  describe 'GET #export_report' do
    let!(:permits) { create_list(:immo_promo_permit, 3, project: project) }

    it 'exports compliance report as PDF' do
      get :export_report, params: {
        project_id: project.id,
        format: :pdf
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
    end

    it 'exports compliance report as Excel' do
      get :export_report, params: {
        project_id: project.id,
        format: :xlsx
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/spreadsheetml/)
    end

    it 'includes regulatory analysis' do
      get :export_report, params: {
        project_id: project.id,
        format: :pdf,
        include_analysis: true
      }
      
      report_data = assigns(:report_data)
      expect(report_data).to include(:regulatory_analysis)
      expect(report_data[:regulatory_analysis]).to include(:compliance_score, :risk_areas)
    end
  end

  describe 'JSON API' do
    it 'returns workflow status as JSON' do
      get :dashboard, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('permits', 'compliance_score', 'upcoming_deadlines')
    end

    it 'returns critical path as JSON' do
      get :critical_path, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('critical_permits', 'dependencies', 'bottlenecks')
    end
  end
end