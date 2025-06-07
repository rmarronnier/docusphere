require 'rails_helper'

RSpec.describe Immo::Promo::ProjectsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, role: 'admin') }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }

  before do
    sign_in user
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:verify_authorized).and_return(true)
    allow(controller).to receive(:verify_policy_scoped).and_return(true)
  end

  describe 'GET #index' do
    let!(:other_org_project) { create(:immo_promo_project) }
    
    before do
      project # ensure it's created
      get :index
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'assigns @projects' do
      expect(assigns(:projects)).to include(project)
      expect(assigns(:projects)).not_to include(other_org_project)
    end

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #show' do
    before { get :show, params: { id: project.id } }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'assigns @project' do
      expect(assigns(:project)).to eq(project)
    end

    it 'renders the show template' do
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #new' do
    before { get :new }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'assigns a new @project' do
      expect(assigns(:project)).to be_a_new(Immo::Promo::Project)
      expect(assigns(:project).organization).to eq(organization)
    end

    it 'renders the new template' do
      expect(response).to render_template(:new)
    end
  end

  describe 'GET #edit' do
    before { get :edit, params: { id: project.id } }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'assigns @project' do
      expect(assigns(:project)).to eq(project)
    end

    it 'renders the edit template' do
      expect(response).to render_template(:edit)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        name: 'Test Project',
        reference: 'TEST-001',
        project_type: 'residential',
        description: 'Test description',
        start_date: Date.current,
        end_date: Date.current + 1.year,
        total_budget_cents: 100_000_000
      }
    end

    context 'with valid parameters' do
      it 'creates a new project' do
        expect {
          post :create, params: { immo_promo_project: valid_attributes }
        }.to change(Immo::Promo::Project, :count).by(1)
      end

      it 'assigns the current user as project manager' do
        post :create, params: { immo_promo_project: valid_attributes }
        expect(assigns(:project).project_manager).to eq(user)
      end

      it 'assigns the current organization' do
        post :create, params: { immo_promo_project: valid_attributes }
        expect(assigns(:project).organization).to eq(organization)
      end

      it 'redirects to the created project' do
        post :create, params: { immo_promo_project: valid_attributes }
        expect(response).to redirect_to(immo_promo_project_path(assigns(:project)))
      end

      it 'sets a success notice' do
        post :create, params: { immo_promo_project: valid_attributes }
        expect(flash[:notice]).to eq('Projet créé avec succès.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not create a new project' do
        expect {
          post :create, params: { immo_promo_project: invalid_attributes }
        }.not_to change(Immo::Promo::Project, :count)
      end

      it 'renders the new template with errors' do
        post :create, params: { immo_promo_project: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) { { name: 'Updated Project Name' } }

    context 'with valid parameters' do
      it 'updates the requested project' do
        patch :update, params: { id: project.id, immo_promo_project: new_attributes }
        project.reload
        expect(project.name).to eq('Updated Project Name')
      end

      it 'redirects to the project' do
        patch :update, params: { id: project.id, immo_promo_project: new_attributes }
        expect(response).to redirect_to(immo_promo_project_path(project))
      end

      it 'sets a success notice' do
        patch :update, params: { id: project.id, immo_promo_project: new_attributes }
        expect(flash[:notice]).to eq('Projet mis à jour avec succès.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not update the project' do
        original_name = project.name
        patch :update, params: { id: project.id, immo_promo_project: invalid_attributes }
        project.reload
        expect(project.name).to eq(original_name)
      end

      it 'renders the edit template with errors' do
        patch :update, params: { id: project.id, immo_promo_project: invalid_attributes }
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested project' do
      project # ensure it's created
      expect {
        delete :destroy, params: { id: project.id }
      }.to change(Immo::Promo::Project, :count).by(-1)
    end

    it 'redirects to the projects list' do
      delete :destroy, params: { id: project.id }
      expect(response).to redirect_to(immo_promo_projects_url)
    end

    it 'sets a success notice' do
      delete :destroy, params: { id: project.id }
      expect(flash[:notice]).to eq('Projet supprimé avec succès.')
    end
  end

  describe 'GET #dashboard' do
    before { get :dashboard, params: { id: project.id } }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'assigns @project' do
      expect(assigns(:project)).to eq(project)
    end

    it 'renders the dashboard template' do
      expect(response).to render_template(:dashboard)
    end
  end

  describe 'private methods' do
    describe '#project_params' do
      let(:params) do
        {
          immo_promo_project: {
            name: 'Test Project',
            reference: 'TEST-001',
            description: 'Test description',
            project_type: 'residential',
            status: 'active',
            start_date: Date.current,
            end_date: Date.current + 1.year,
            address: '123 Test St',
            city: 'Test City',
            postal_code: '12345',
            country: 'France',
            total_budget_cents: 100_000_000,
            total_units: 50,
            total_surface_area: 2500.0,
            description_short: 'Short desc',
            forbidden_param: 'should not be allowed'
          }
        }
      end

      before do
        controller.params = ActionController::Parameters.new(params)
      end

      it 'permits only allowed parameters' do
        allowed_params = controller.send(:project_params)
        expect(allowed_params).to include(:name, :reference, :description, :project_type)
        expect(allowed_params).not_to include(:forbidden_param)
      end
    end

    describe '#set_project' do
      it 'finds project by id within organization scope' do
        controller.params = ActionController::Parameters.new(id: project.id)
        controller.send(:set_project)
        expect(assigns(:project)).to eq(project)
      end

      it 'raises error for project from different organization' do
        other_project = create(:immo_promo_project)
        controller.params = ActionController::Parameters.new(id: other_project.id)
        
        expect {
          controller.send(:set_project)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end