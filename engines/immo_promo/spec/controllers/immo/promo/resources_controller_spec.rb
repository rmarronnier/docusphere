require 'rails_helper'

module Immo
  module Promo
    RSpec.describe ResourcesController, type: :controller do
      routes { Immo::Promo::Engine.routes }
      
      let(:organization) { create(:organization) }
      let(:chef_projet) { create(:user, organization: organization) }
      let(:direction) { create(:user, organization: organization) }
      let(:regular_user) { create(:user, organization: organization) }
      let(:resource) { create(:resource, organization: organization) }
      let(:project) { create(:project, organization: organization) }
      let(:team) { create(:team, organization: organization) }
      
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
          
          it 'loads resources and teams' do
            resource # create it
            team # create it
            get :index
            expect(assigns(:resources)).to include(resource)
            expect(assigns(:teams)).to include(team)
            expect(assigns(:resource_allocation)).to be_present
            expect(assigns(:availability_matrix)).to be_present
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
          get :show, params: { id: resource.id }
          expect(response).to have_http_status(:success)
        end
        
        it 'loads resource data' do
          get :show, params: { id: resource.id }
          expect(assigns(:resource)).to eq(resource)
          expect(assigns(:current_assignments)).to be_present
          expect(assigns(:availability)).to be_present
          expect(assigns(:skills)).to be_present
          expect(assigns(:performance_metrics)).to be_present
        end
      end
      
      describe 'GET #allocation' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :allocation
          expect(response).to have_http_status(:success)
        end
        
        it 'loads allocation data' do
          project # create it
          allow_any_instance_of(StakeholderAllocationService).to receive(:allocation_overview)
            .and_return({ resources: [], summary: {} })
          
          get :allocation
          expect(assigns(:projects)).to include(project)
          expect(assigns(:allocation_data)).to be_present
          expect(assigns(:conflicts)).to be_present
        end
        
        it 'responds to json' do
          allow_any_instance_of(StakeholderAllocationService).to receive(:allocation_overview)
            .and_return({ resources: [] })
          
          get :allocation, format: :json
          expect(response.content_type).to include('application/json')
        end
        
        it 'responds to xlsx' do
          allow_any_instance_of(ResourcesController).to receive(:generate_allocation_report)
            .and_return('Excel data')
          
          get :allocation, format: :xlsx
          expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        end
      end
      
      describe 'GET #availability' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :availability
          expect(response).to have_http_status(:success)
        end
        
        it 'calculates availability for date range' do
          get :availability, params: { start_date: '2024-01-01', end_date: '2024-01-31' }
          expect(assigns(:date_range)).to eq(Date.parse('2024-01-01')..Date.parse('2024-01-31'))
          expect(assigns(:availability_data)).to be_present
        end
        
        it 'responds to json' do
          get :availability, format: :json
          expect(response.content_type).to include('application/json')
        end
      end
      
      describe 'POST #assign' do
        before { sign_in chef_projet }
        
        let(:valid_params) do
          {
            id: resource.id,
            project_id: project.id,
            assignment: {
              start_date: Date.current,
              end_date: 1.month.from_now,
              allocation_percentage: 80,
              role: 'developer'
            }
          }
        end
        
        it 'creates assignment' do
          expect {
            post :assign, params: valid_params
          }.to change(Stakeholder, :count).by(1)
        end
        
        it 'redirects with success' do
          post :assign, params: valid_params
          expect(response).to redirect_to(resources_path)
          expect(flash[:notice]).to eq('Ressource assignée avec succès')
        end
        
        context 'with invalid params' do
          it 'redirects with error' do
            post :assign, params: { id: resource.id, project_id: project.id, assignment: { role: '' } }
            expect(response).to redirect_to(resources_path)
            expect(flash[:alert]).to eq('Erreur lors de l\'assignation')
          end
        end
      end
      
      describe 'GET #workload' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :workload, params: { id: resource.id }
          expect(response).to have_http_status(:success)
        end
        
        it 'calculates workload data' do
          allow_any_instance_of(Resource).to receive(:workload_for_week).and_return(40)
          allow_any_instance_of(Resource).to receive(:workload_for_month).and_return(160)
          allow_any_instance_of(Resource).to receive(:workload_forecast).and_return({})
          
          get :workload, params: { id: resource.id }
          expect(assigns(:workload_data)).to include(:current_week, :current_month, :forecast)
          expect(assigns(:recommendations)).to be_present
        end
        
        it 'responds to json' do
          get :workload, params: { id: resource.id }, format: :json
          json = JSON.parse(response.body)
          expect(json).to include('workload', 'recommendations')
        end
      end
      
      describe 'GET #capacity_planning' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :capacity_planning
          expect(response).to have_http_status(:success)
        end
        
        it 'loads capacity data' do
          team # create it
          allow_any_instance_of(TeamCapacityService).to receive(:analyze_capacity)
            .and_return({ teams: [], total_capacity: 0 })
          
          get :capacity_planning
          expect(assigns(:teams)).to include(team)
          expect(assigns(:capacity_data)).to be_present
          expect(assigns(:forecast)).to be_present
        end
      end
      
      describe 'GET #skills_matrix' do
        before { sign_in chef_projet }
        
        it 'returns success' do
          get :skills_matrix
          expect(response).to have_http_status(:success)
        end
        
        it 'builds skills matrix' do
          skill = create(:skill)
          resource # create it
          
          get :skills_matrix
          expect(assigns(:resources)).to include(resource)
          expect(assigns(:skills)).to include(skill)
          expect(assigns(:matrix)).to be_present
          expect(assigns(:gaps)).to be_present
        end
      end
      
      describe 'private methods' do
        before { sign_in chef_projet }
        
        it 'calculates resource allocation correctly' do
          allow(resource).to receive(:current_workload_percentage).and_return(75)
          allow(resource).to receive(:available_capacity).and_return(25)
          allow(resource).to receive_message_chain(:assignments, :active, :count).and_return(2)
          
          get :index
          allocation = assigns(:resource_allocation)[resource.id]
          expect(allocation).to include(
            name: resource.name,
            current_load: 75,
            available_capacity: 25,
            assignments: 2
          )
        end
        
        it 'detects allocation conflicts' do
          allow(resource).to receive(:overallocated?).and_return(true)
          allow(resource).to receive(:current_workload_percentage).and_return(120)
          allow(Resource).to receive(:includes).and_return([resource])
          
          get :allocation
          conflicts = assigns(:conflicts)
          expect(conflicts).to be_present
          expect(conflicts.first[:severity]).to eq('high')
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