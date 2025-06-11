require 'rails_helper'

RSpec.describe Immo::Promo::StakeholdersController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns stakeholders' do
      stakeholder # create it
      get :index, params: { project_id: project.id }
      expect(assigns(:stakeholders)).to include(stakeholder)
    end

    it 'filters by role when provided' do
      architect = create(:immo_promo_stakeholder, project: project, role: 'architect')
      contractor = create(:immo_promo_stakeholder, project: project, role: 'contractor')
      
      get :index, params: { project_id: project.id, role: 'architect' }
      expect(assigns(:stakeholders)).to include(architect)
      expect(assigns(:stakeholders)).not_to include(contractor)
    end

    it 'filters by status when provided' do
      active_stakeholder = create(:immo_promo_stakeholder, project: project, status: 'active')
      pending_stakeholder = create(:immo_promo_stakeholder, project: project, status: 'pending')
      
      get :index, params: { project_id: project.id, status: 'active' }
      expect(assigns(:stakeholders)).to include(active_stakeholder)
      expect(assigns(:stakeholders)).not_to include(pending_stakeholder)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { project_id: project.id, id: stakeholder.id }
      expect(response).to be_successful
    end

    it 'assigns the requested stakeholder' do
      get :show, params: { project_id: project.id, id: stakeholder.id }
      expect(assigns(:stakeholder)).to eq(stakeholder)
    end

    it 'assigns certifications' do
      get :show, params: { project_id: project.id, id: stakeholder.id }
      expect(assigns(:certifications)).to be_present
    end

    it 'assigns contracts' do
      get :show, params: { project_id: project.id, id: stakeholder.id }
      expect(assigns(:contracts)).to be_present
    end

    it 'assigns recent activity' do
      get :show, params: { project_id: project.id, id: stakeholder.id }
      expect(assigns(:recent_activity)).to be_present
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns a new stakeholder' do
      get :new, params: { project_id: project.id }
      expect(assigns(:stakeholder)).to be_a_new(Immo::Promo::Stakeholder)
    end

    it 'assigns available users' do
      get :new, params: { project_id: project.id }
      expect(assigns(:available_users)).to be_present
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { project_id: project.id, id: stakeholder.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_attributes) do
        {
          name: 'New Stakeholder',
          role: 'architect',
          status: 'active',
          company: 'Architecture Co.',
          email: 'stakeholder@example.com',
          phone: '+33123456789'
        }
      end

      it 'creates a new Stakeholder' do
        expect {
          post :create, params: { project_id: project.id, immo_promo_stakeholder: valid_attributes }
        }.to change(Immo::Promo::Stakeholder, :count).by(1)
      end

      it 'redirects to the created stakeholder' do
        post :create, params: { project_id: project.id, immo_promo_stakeholder: valid_attributes }
        expect(response).to redirect_to("/immo/promo/projects/#{project.id}/stakeholders/#{Immo::Promo::Stakeholder.last.id}")
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'returns an unprocessable entity response' do
        post :create, params: { project_id: project.id, immo_promo_stakeholder: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'assigns available users on failure' do
        post :create, params: { project_id: project.id, immo_promo_stakeholder: invalid_attributes }
        expect(assigns(:available_users)).to be_present
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Stakeholder Name' }
      end

      it 'updates the requested stakeholder' do
        put :update, params: { project_id: project.id, id: stakeholder.id, immo_promo_stakeholder: new_attributes }
        stakeholder.reload
        expect(stakeholder.name).to eq('Updated Stakeholder Name')
      end

      it 'redirects to the stakeholder' do
        put :update, params: { project_id: project.id, id: stakeholder.id, immo_promo_stakeholder: new_attributes }
        expect(response).to redirect_to("/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}")
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested stakeholder when allowed' do
      stakeholder # create it
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:can_be_deleted?).and_return(true)
      
      expect {
        delete :destroy, params: { project_id: project.id, id: stakeholder.id }
      }.to change(Immo::Promo::Stakeholder, :count).by(-1)
    end

    it 'redirects to the stakeholders list' do
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:can_be_deleted?).and_return(true)
      delete :destroy, params: { project_id: project.id, id: stakeholder.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/stakeholders")
    end

    it 'shows error when stakeholder cannot be deleted' do
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:can_be_deleted?).and_return(false)
      delete :destroy, params: { project_id: project.id, id: stakeholder.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #approve' do
    it 'approves the stakeholder when allowed' do
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:may_approve?).and_return(true)
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:approve!)
      
      post :approve, params: { project_id: project.id, id: stakeholder.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}")
      expect(flash[:notice]).to be_present
    end

    it 'shows error when stakeholder cannot be approved' do
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:may_approve?).and_return(false)
      
      post :approve, params: { project_id: project.id, id: stakeholder.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #reject' do
    it 'rejects the stakeholder when allowed' do
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:may_reject?).and_return(true)
      allow_any_instance_of(Immo::Promo::Stakeholder).to receive(:reject!)
      
      post :reject, params: { project_id: project.id, id: stakeholder.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}")
      expect(flash[:notice]).to be_present
    end
  end

  describe 'authorization' do
    it 'authorizes the project in set_project' do
      expect(controller).to receive(:authorize).with(project)
      get :show, params: { project_id: project.id, id: stakeholder.id }
    end

    it 'authorizes the stakeholder in set_stakeholder' do
      expect(controller).to receive(:authorize).with(stakeholder)
      get :show, params: { project_id: project.id, id: stakeholder.id }
    end

    it 'authorizes new stakeholder in new action' do
      expect(controller).to receive(:authorize).with(an_instance_of(Immo::Promo::Stakeholder))
      get :new, params: { project_id: project.id }
    end

    it 'authorizes new stakeholder in create action' do
      expect(controller).to receive(:authorize).with(an_instance_of(Immo::Promo::Stakeholder))
      post :create, params: { project_id: project.id, immo_promo_stakeholder: { name: 'Test' } }
    end
  end
end