require 'rails_helper'

RSpec.describe Immo::Promo::PhasesController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  # Helper methods for routes
  def project_phase_path(project, phase)
    "/immo/promo/projects/#{project.id}/phases/#{phase.id}"
  end
  
  def project_path(project)
    "/immo/promo/projects/#{project.id}"
  end
  
  let(:user) { create(:user, :admin, organization: organization) }
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:phase) { create(:immo_promo_phase, project: project) }

  before do
    sign_in user
  end

  describe 'GET #show' do
    it 'returns success for authorized user' do
      get :show, params: { project_id: project.id, id: phase.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads tasks for the phase' do
      task = create(:immo_promo_task, phase: phase)
      get :show, params: { project_id: project.id, id: phase.id }
      expect(assigns(:tasks)).to include(task)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        name: 'New Phase',
        description: 'Description',
        phase_type: 'construction',
        start_date: Date.today,
        end_date: Date.today + 30.days,
        position: 1
      }
    end

    context 'with valid params' do
      it 'creates a new phase' do
        expect {
          post :create, params: { project_id: project.id, immo_promo_phase: valid_attributes }
        }.to change(Immo::Promo::Phase, :count).by(1)
      end

      it 'redirects to the created phase' do
        post :create, params: { project_id: project.id, immo_promo_phase: valid_attributes }
        expect(response).to redirect_to(project_phase_path(project, Immo::Promo::Phase.last))
      end
    end

    context 'with invalid params' do
      it 'does not create a new phase' do
        expect {
          post :create, params: { project_id: project.id, immo_promo_phase: { name: '' } }
        }.not_to change(Immo::Promo::Phase, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) { { name: 'Updated Phase' } }

    it 'updates the phase' do
      patch :update, params: { project_id: project.id, id: phase.id, immo_promo_phase: new_attributes }
      phase.reload
      expect(phase.name).to eq('Updated Phase')
    end

    it 'redirects to the phase' do
      patch :update, params: { project_id: project.id, id: phase.id, immo_promo_phase: new_attributes }
      expect(response).to redirect_to(project_phase_path(project, phase))
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the phase' do
      phase # create it first
      expect {
        delete :destroy, params: { project_id: project.id, id: phase.id }
      }.to change(Immo::Promo::Phase, :count).by(-1)
    end

    it 'redirects to project' do
      delete :destroy, params: { project_id: project.id, id: phase.id }
      expect(response).to redirect_to(project_path(project))
    end
  end

  describe 'PATCH #complete' do
    it 'marks the phase as completed' do
      patch :complete, params: { project_id: project.id, id: phase.id }
      phase.reload
      expect(phase.status).to eq('completed')
    end

    it 'redirects to the phase' do
      patch :complete, params: { project_id: project.id, id: phase.id }
      expect(response).to redirect_to(project_phase_path(project, phase))
    end
  end
end
