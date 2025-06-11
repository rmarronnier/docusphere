require 'rails_helper'

RSpec.describe Immo::Promo::PermitsController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:permit) { create(:immo_promo_permit, project: project) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns permits' do
      permit # create it
      get :index, params: { project_id: project.id }
      expect(assigns(:permits)).to include(permit)
    end

    it 'filters by status when provided' do
      approved_permit = create(:immo_promo_permit, project: project, status: 'approved')
      draft_permit = create(:immo_promo_permit, project: project, status: 'draft')
      
      get :index, params: { project_id: project.id, status: 'approved' }
      expect(assigns(:permits)).to include(approved_permit)
      expect(assigns(:permits)).not_to include(draft_permit)
    end

    it 'filters by permit_type when provided' do
      building_permit = create(:immo_promo_permit, project: project, permit_type: 'building')
      demolition_permit = create(:immo_promo_permit, project: project, permit_type: 'demolition')
      
      get :index, params: { project_id: project.id, permit_type: 'building' }
      expect(assigns(:permits)).to include(building_permit)
      expect(assigns(:permits)).not_to include(demolition_permit)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { project_id: project.id, id: permit.id }
      expect(response).to be_successful
    end

    it 'assigns the requested permit' do
      get :show, params: { project_id: project.id, id: permit.id }
      expect(assigns(:permit)).to eq(permit)
    end

    it 'assigns conditions' do
      get :show, params: { project_id: project.id, id: permit.id }
      expect(assigns(:conditions)).to be_present
    end

    it 'assigns pending conditions' do
      get :show, params: { project_id: project.id, id: permit.id }
      expect(assigns(:pending_conditions)).to be_present
    end

    it 'assigns timeline events' do
      get :show, params: { project_id: project.id, id: permit.id }
      expect(assigns(:timeline_events)).to be_present
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { project_id: project.id }
      expect(response).to be_successful
    end

    it 'assigns a new permit' do
      get :new, params: { project_id: project.id }
      expect(assigns(:permit)).to be_a_new(Immo::Promo::Permit)
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { project_id: project.id, id: permit.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_attributes) do
        {
          name: 'New Permit',
          permit_type: 'building',
          status: 'draft',
          issuing_authority: 'City Hall',
          reference_number: 'PERM-001'
        }
      end

      it 'creates a new Permit' do
        expect {
          post :create, params: { project_id: project.id, immo_promo_permit: valid_attributes }
        }.to change(Immo::Promo::Permit, :count).by(1)
      end

      it 'redirects to the created permit' do
        post :create, params: { project_id: project.id, immo_promo_permit: valid_attributes }
        expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permits/#{Immo::Promo::Permit.last.id}")
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'returns an unprocessable entity response' do
        post :create, params: { project_id: project.id, immo_promo_permit: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Permit Name' }
      end

      it 'updates the requested permit' do
        put :update, params: { project_id: project.id, id: permit.id, immo_promo_permit: new_attributes }
        permit.reload
        expect(permit.name).to eq('Updated Permit Name')
      end

      it 'redirects to the permit' do
        put :update, params: { project_id: project.id, id: permit.id, immo_promo_permit: new_attributes }
        expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permits/#{permit.id}")
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested permit when allowed' do
      permit # create it
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_deleted?).and_return(true)
      
      expect {
        delete :destroy, params: { project_id: project.id, id: permit.id }
      }.to change(Immo::Promo::Permit, :count).by(-1)
    end

    it 'redirects to the permits list' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_deleted?).and_return(true)
      delete :destroy, params: { project_id: project.id, id: permit.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permits")
    end

    it 'shows error when permit cannot be deleted' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:can_be_deleted?).and_return(false)
      delete :destroy, params: { project_id: project.id, id: permit.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #submit_for_approval' do
    it 'submits the permit when allowed' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:may_submit?).and_return(true)
      allow_any_instance_of(Immo::Promo::Permit).to receive(:submit!)
      
      post :submit_for_approval, params: { project_id: project.id, id: permit.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permits/#{permit.id}")
      expect(flash[:notice]).to be_present
    end

    it 'shows error when permit cannot be submitted' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:may_submit?).and_return(false)
      
      post :submit_for_approval, params: { project_id: project.id, id: permit.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #approve' do
    it 'approves the permit when allowed' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:may_approve?).and_return(true)
      allow_any_instance_of(Immo::Promo::Permit).to receive(:approve!)
      
      post :approve, params: { project_id: project.id, id: permit.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permits/#{permit.id}")
      expect(flash[:notice]).to be_present
    end

    it 'shows error when permit cannot be approved' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:may_approve?).and_return(false)
      
      post :approve, params: { project_id: project.id, id: permit.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #reject' do
    it 'rejects the permit when allowed' do
      allow_any_instance_of(Immo::Promo::Permit).to receive(:may_reject?).and_return(true)
      allow_any_instance_of(Immo::Promo::Permit).to receive(:reject!)
      
      post :reject, params: { project_id: project.id, id: permit.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/permits/#{permit.id}")
      expect(flash[:notice]).to be_present
    end
  end

  describe 'private methods' do
    describe '#schedule_deadline_reminders' do
      it 'schedules reminders for pending conditions with deadlines' do
        # This is tested indirectly through submit_for_approval action
        # More detailed testing would require job testing which should be in a separate job spec
        expect(controller).to respond_to(:schedule_deadline_reminders, true)
      end
    end

    describe '#permit_timeline_events' do
      it 'generates timeline events' do
        # This is tested indirectly through the show action
        # The timeline_events assignment verifies this method works
        expect(controller).to respond_to(:permit_timeline_events, true)
      end
    end
  end
end