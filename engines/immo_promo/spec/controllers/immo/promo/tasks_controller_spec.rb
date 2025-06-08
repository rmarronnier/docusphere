require 'rails_helper'

RSpec.describe Immo::Promo::TasksController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:user) { create(:user, organization: organization, role: 'admin') }
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  let(:task) { create(:immo_promo_task, phase: phase) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns success' do
      get :index, params: { project_id: project.id, phase_id: phase.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads tasks for the phase' do
      task1 = create(:immo_promo_task, phase: phase)
      task2 = create(:immo_promo_task, phase: phase)
      get :index, params: { project_id: project.id, phase_id: phase.id }
      expect(assigns(:tasks)).to include(task1, task2)
    end
  end

  describe 'GET #show' do
    it 'returns success for authorized user' do
      get :show, params: { project_id: project.id, phase_id: phase.id, id: task.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads time logs for the task' do
      time_log = create(:immo_promo_time_log, task: task, user: user)
      get :show, params: { project_id: project.id, phase_id: phase.id, id: task.id }
      expect(assigns(:time_logs)).to include(time_log)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        name: 'New Task',
        description: 'Description',
        task_type: 'technical',
        start_date: Date.today,
        end_date: Date.today + 7.days,
        estimated_hours: 40
      }
    end

    context 'with valid params' do
      it 'creates a new task' do
        expect {
          post :create, params: {
            project_id: project.id,
            phase_id: phase.id,
            immo_promo_task: valid_attributes
          }
        }.to change(Immo::Promo::Task, :count).by(1)
      end

      it 'redirects to phase' do
        post :create, params: {
          project_id: project.id,
          phase_id: phase.id,
          immo_promo_task: valid_attributes
        }
        expect(response).to redirect_to(controller.immo_promo_engine.project_phase_task_path(project, phase, Immo::Promo::Task.last))
      end
    end

    context 'with invalid params' do
      it 'does not create a new task' do
        expect {
          post :create, params: {
            project_id: project.id,
            phase_id: phase.id,
            immo_promo_task: { name: '' }
          }
        }.not_to change(Immo::Promo::Task, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) { { name: 'Updated Task' } }

    it 'updates the task' do
      patch :update, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id,
        immo_promo_task: new_attributes
      }
      task.reload
      expect(task.name).to eq('Updated Task')
    end

    it 'redirects to task' do
      patch :update, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id,
        immo_promo_task: new_attributes
      }
      expect(response).to redirect_to(controller.immo_promo_engine.project_phase_task_path(project, phase, task))
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the task' do
      task # create it first
      expect {
        delete :destroy, params: {
          project_id: project.id,
          phase_id: phase.id,
          id: task.id
        }
      }.to change(Immo::Promo::Task, :count).by(-1)
    end

    it 'redirects to phase' do
      delete :destroy, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id
      }
      expect(response).to redirect_to(controller.immo_promo_engine.project_phase_path(project, phase))
    end
  end

  describe 'PATCH #complete' do
    it 'marks the task as completed' do
      patch :complete, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id
      }
      task.reload
      expect(task.status).to eq('completed')
    end

    it 'redirects to task' do
      patch :complete, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id
      }
      expect(response).to redirect_to(controller.immo_promo_engine.project_phase_task_path(project, phase, task))
    end
  end

  describe 'PATCH #assign' do
    let(:assignee) { create(:user, organization: organization) }

    it 'assigns the task to a user' do
      patch :assign, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id,
        user_id: assignee.id
      }
      task.reload
      expect(task.assigned_to).to eq(assignee)
    end

    it 'redirects to task' do
      patch :assign, params: {
        project_id: project.id,
        phase_id: phase.id,
        id: task.id,
        user_id: assignee.id
      }
      expect(response).to redirect_to(controller.immo_promo_engine.project_phase_task_path(project, phase, task))
    end
  end

  describe 'GET #my_tasks' do
    it 'returns tasks assigned to current user' do
      task1 = create(:immo_promo_task, phase: phase, assigned_to: user)
      task2 = create(:immo_promo_task, phase: phase, assigned_to: user)
      task3 = create(:immo_promo_task, phase: phase) # not assigned to user

      get :my_tasks, params: { project_id: project.id, phase_id: phase.id }

      expect(assigns(:tasks)).to include(task1, task2)
      expect(assigns(:tasks)).not_to include(task3)
    end
  end
end
