require 'rails_helper'

module Immo
  module Promo
    RSpec.describe PlanningController, type: :controller do
      routes { Immo::Promo::Engine.routes }
      
      let(:organization) { create(:organization) }
      let(:chef_projet) { create(:user, organization: organization) }
      let(:direction) { create(:user, organization: organization) }
      let(:regular_user) { create(:user, organization: organization) }
      let(:project) { create(:project, organization: organization) }
      let(:phase) { create(:phase, project: project) }
      let(:task) { create(:task, phase: phase) }
      let(:milestone) { create(:milestone, project: project) }
      
      before do
        chef_projet.add_role(:chef_projet)
        direction.add_role(:direction)
      end
      
      describe 'GET #index' do
        context 'as authorized user' do
          before { sign_in chef_projet }
          
          it 'returns success' do
            get :index
            expect(response).to have_http_status(:success)
          end
          
          it 'loads projects and events' do
            project # create it
            milestone # create it
            get :index
            expect(assigns(:projects)).to include(project)
            expect(assigns(:calendar_events)).to be_present
            expect(assigns(:milestones)).to include(milestone)
          end
          
          it 'detects resource conflicts' do
            get :index
            expect(assigns(:resource_conflicts)).to be_present
          end
        end
        
        context 'as unauthorized user' do
          before { sign_in regular_user }
          
          it 'redirects to root' do
            get :index
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq('Accès non autorisé')
          end
        end
      end
      
      describe 'GET #show' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :show, params: { id: project.id }
          expect(response).to have_http_status(:success)
        end
        
        it 'loads project data' do
          get :show, params: { id: project.id }
          expect(assigns(:project)).to eq(project)
          expect(assigns(:phases)).to eq(project.phases)
          expect(assigns(:gantt_data)).to be_present
          expect(assigns(:critical_path)).to be_present
        end
      end
      
      describe 'GET #calendar' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :calendar
          expect(response).to have_http_status(:success)
        end
        
        it 'supports different view types' do
          get :calendar, params: { view: 'week' }
          expect(assigns(:view_type)).to eq('week')
        end
        
        it 'responds to json' do
          get :calendar, format: :json
          expect(response.content_type).to include('application/json')
        end
        
        it 'responds to ics' do
          get :calendar, format: :ics
          expect(response.content_type).to eq('text/calendar')
          expect(response.headers['Content-Disposition']).to include('planning.ics')
        end
      end
      
      describe 'GET #timeline' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :timeline
          expect(response).to have_http_status(:success)
        end
        
        it 'loads active projects' do
          active_project = create(:project, status: 'active', organization: organization)
          inactive_project = create(:project, status: 'completed', organization: organization)
          
          get :timeline
          expect(assigns(:projects)).to include(active_project)
          expect(assigns(:projects)).not_to include(inactive_project)
        end
        
        it 'builds timeline data' do
          project # create it
          get :timeline
          expect(assigns(:timeline_data)).to be_present
        end
      end
      
      describe 'PATCH #update_task' do
        before { sign_in chef_projet }
        
        let(:valid_params) do
          {
            id: task.id,
            task: {
              name: 'Updated Task',
              progress: 75
            }
          }
        end
        
        it 'updates task' do
          patch :update_task, params: valid_params, format: :json
          expect(task.reload.name).to eq('Updated Task')
          expect(task.progress).to eq(75)
        end
        
        it 'notifies task update' do
          expect_any_instance_of(NotificationService).to receive(:notify_task_update)
          patch :update_task, params: valid_params, format: :json
        end
        
        it 'returns json response' do
          patch :update_task, params: valid_params, format: :json
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['task']).to be_present
        end
        
        context 'with invalid params' do
          it 'returns error' do
            patch :update_task, params: { id: task.id, task: { name: '' } }, format: :json
            json = JSON.parse(response.body)
            expect(json['success']).to be false
            expect(json['errors']).to be_present
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
      
      describe 'POST #reschedule' do
        before { sign_in chef_projet }
        
        it 'reschedules project' do
          allow(project).to receive(:reschedule!).and_return(true)
          post :reschedule, params: { id: project.id, start_date: '2024-12-31' }
          expect(project).to have_received(:reschedule!).with(Date.parse('2024-12-31'))
        end
        
        it 'redirects with success' do
          allow_any_instance_of(Project).to receive(:reschedule!).and_return(true)
          post :reschedule, params: { id: project.id, start_date: '2024-12-31' }
          expect(response).to redirect_to(planning_path(project))
          expect(flash[:notice]).to eq('Planning mis à jour avec succès')
        end
        
        context 'when reschedule fails' do
          it 'redirects with error' do
            allow_any_instance_of(Project).to receive(:reschedule!).and_return(false)
            post :reschedule, params: { id: project.id, start_date: '2024-12-31' }
            expect(response).to redirect_to(planning_path(project))
            expect(flash[:alert]).to eq('Erreur lors de la mise à jour du planning')
          end
        end
      end
      
      describe 'private methods' do
        before { sign_in chef_projet }
        
        it 'builds calendar events correctly' do
          task # create it
          milestone # create it
          
          get :index
          events = assigns(:calendar_events)
          
          task_event = events.find { |e| e[:id] == "task_#{task.id}" }
          expect(task_event).to include(
            title: task.name,
            start: task.start_date,
            end: task.end_date,
            type: 'task'
          )
          
          milestone_event = events.find { |e| e[:id] == "milestone_#{milestone.id}" }
          expect(milestone_event).to include(
            title: milestone.name,
            start: milestone.target_date,
            type: 'milestone'
          )
        end
      end
      
      describe 'authorization' do
        it 'allows chef_projet users' do
          sign_in chef_projet
          get :index
          expect(response).to have_http_status(:success)
        end
        
        it 'allows direction users' do
          sign_in direction
          get :index
          expect(response).to have_http_status(:success)
        end
        
        it 'denies regular users' do
          sign_in regular_user
          get :index
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end