require 'rails_helper'

RSpec.describe Immo::Promo::ProjectsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  before do
    sign_in user
  end
  
  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end
    
    it 'assigns projects' do
      project # create it
      get :index
      expect(assigns(:projects)).to include(project)
    end
  end
  
  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: project.id }
      expect(response).to be_successful
    end
    
    it 'assigns the requested project' do
      get :show, params: { id: project.id }
      expect(assigns(:project)).to eq(project)
    end
  end
  
  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end
    
    it 'assigns a new project' do
      get :new
      expect(assigns(:project)).to be_a_new(Immo::Promo::Project)
    end
  end
  
  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: project.id }
      expect(response).to be_successful
    end
  end
  
  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_attributes) do
        {
          name: 'New Project',
          reference_number: 'NEW-001',
          project_type: 'residential',
          status: 'planning',
          start_date: Date.current,
          expected_completion_date: Date.current + 1.year,
          total_budget_cents: 1_000_000_00
        }
      end
      
      it 'creates a new Project' do
        expect {
          post :create, params: { immo_promo_project: valid_attributes }
        }.to change(Immo::Promo::Project, :count).by(1)
      end
      
      it 'redirects to the created project' do
        post :create, params: { immo_promo_project: valid_attributes }
        expect(response).to redirect_to(immo_promo_project_path(Immo::Promo::Project.last))
      end
    end
    
    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end
      
      it 'returns a success response (renders new template)' do
        post :create, params: { immo_promo_project: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end
  
  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Project Name' }
      end
      
      it 'updates the requested project' do
        put :update, params: { id: project.id, immo_promo_project: new_attributes }
        project.reload
        expect(project.name).to eq('Updated Project Name')
      end
      
      it 'redirects to the project' do
        put :update, params: { id: project.id, immo_promo_project: new_attributes }
        expect(response).to redirect_to(immo_promo_project_path(project))
      end
    end
  end
  
  describe 'DELETE #destroy' do
    it 'destroys the requested project' do
      project # create it
      expect {
        delete :destroy, params: { id: project.id }
      }.to change(Immo::Promo::Project, :count).by(-1)
    end
    
    it 'redirects to the projects list' do
      delete :destroy, params: { id: project.id }
      expect(response).to redirect_to(immo_promo_projects_path)
    end
  end
  
  describe 'GET #dashboard' do
    it 'returns a success response' do
      get :dashboard, params: { id: project.id }
      expect(response).to be_successful
    end
    
    it 'assigns statistics' do
      get :dashboard, params: { id: project.id }
      expect(assigns(:stats)).to be_present
    end
  end
end