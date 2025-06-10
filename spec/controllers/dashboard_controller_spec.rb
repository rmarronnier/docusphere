require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:user) { create(:user) }
  let(:user_profile) { create(:user_profile, user: user) }
  
  before do
    sign_in user
  end
  
  describe 'GET #show' do
    context 'when user has a profile' do
      before { user_profile }
      
      it 'returns a successful response' do
        get :show
        expect(response).to be_successful
      end
      
      it 'assigns @dashboard_data' do
        get :show
        expect(assigns(:dashboard_data)).to be_present
      end
      
      it 'includes widgets in dashboard data' do
        get :show
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:widgets]).to be_an(Array)
      end
      
      it 'includes actions in dashboard data' do
        get :show
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:actions]).to be_an(Array)
      end
      
      it 'includes navigation in dashboard data' do
        get :show
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:navigation]).to be_an(Array)
      end
      
      it 'includes notifications in dashboard data' do
        get :show
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:notifications]).to be_an(Array)
      end
      
      it 'includes metrics in dashboard data' do
        get :show
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:metrics]).to be_a(Hash)
      end
    end
    
    context 'when user has no profile' do
      it 'creates a default profile' do
        expect { get :show }.to change(UserProfile, :count).by(1)
      end
      
      it 'returns a successful response' do
        get :show
        expect(response).to be_successful
      end
    end
  end
  
  describe 'POST #update_widget' do
    let(:widget) { create(:dashboard_widget, user_profile: user_profile) }
    
    context 'with valid params' do
      let(:valid_params) do
        {
          id: widget.id,
          widget: {
            position: 2,
            config: { refresh_interval: 60 }
          }
        }
      end
      
      it 'updates the widget position' do
        post :update_widget, params: valid_params
        widget.reload
        expect(widget.position).to eq(2)
      end
      
      it 'updates the widget config' do
        post :update_widget, params: valid_params
        widget.reload
        expect(widget.config['refresh_interval']).to eq(60)
      end
      
      it 'returns success status' do
        post :update_widget, params: valid_params, format: :json
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'with width and height params' do
      let(:resize_params) do
        {
          id: widget.id,
          widget: {
            width: 3,
            height: 2
          }
        }
      end
      
      it 'updates the widget dimensions' do
        post :update_widget, params: resize_params
        widget.reload
        expect(widget.width).to eq(3)
        expect(widget.height).to eq(2)
      end
      
      it 'returns updated widget data with dimensions' do
        post :update_widget, params: resize_params, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response['widget']['width']).to eq(3)
        expect(json_response['widget']['height']).to eq(2)
      end
    end
    
    context 'with invalid widget id' do
      it 'returns not found status' do
        post :update_widget, params: { id: 99999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context 'when widget belongs to another user' do
      let(:other_user) { create(:user) }
      let(:other_profile) { create(:user_profile, user: other_user) }
      let(:other_widget) { create(:dashboard_widget, user_profile: other_profile) }
      
      it 'returns not found status' do
        post :update_widget, params: { id: other_widget.id }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'POST #reorder_widgets' do
    let!(:widget1) { create(:dashboard_widget, user_profile: user_profile, position: 1) }
    let!(:widget2) { create(:dashboard_widget, user_profile: user_profile, position: 2) }
    let!(:widget3) { create(:dashboard_widget, user_profile: user_profile, position: 3) }
    
    context 'with valid widget order' do
      let(:params) do
        {
          widget_ids: [widget3.id, widget1.id, widget2.id]
        }
      end
      
      it 'updates widget positions' do
        post :reorder_widgets, params: params, format: :json
        
        expect(widget1.reload.position).to eq(2)
        expect(widget2.reload.position).to eq(3)
        expect(widget3.reload.position).to eq(1)
      end
      
      it 'returns success status' do
        post :reorder_widgets, params: params, format: :json
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'with widget from another user' do
      let(:other_user) { create(:user) }
      let(:other_profile) { create(:user_profile, user: other_user) }
      let(:other_widget) { create(:dashboard_widget, user_profile: other_profile) }
      
      let(:params) do
        {
          widget_ids: [widget1.id, other_widget.id, widget2.id]
        }
      end
      
      it 'ignores the other user widget' do
        initial_position = other_widget.position
        
        post :reorder_widgets, params: params, format: :json
        
        expect(widget1.reload.position).to eq(1)
        expect(widget2.reload.position).to eq(2)
        # Other widget should remain at its original position
        expect(other_widget.reload.position).to eq(initial_position)
      end
    end
  end
  
  describe 'POST #refresh_widget' do
    let(:widget) { create(:dashboard_widget, user_profile: user_profile) }
    
    context 'with valid widget' do
      it 'returns updated widget data' do
        post :refresh_widget, params: { id: widget.id }, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['widget']).to be_present
      end
      
      it 'updates widget last_refreshed_at' do
        post :refresh_widget, params: { id: widget.id }, format: :json
        widget.reload
        expect(widget.config['last_refreshed_at']).to be_present
        expect(Time.parse(widget.config['last_refreshed_at'])).to be_within(1.second).of(Time.current)
      end
    end
    
    context 'with invalid widget id' do
      it 'returns not found status' do
        post :refresh_widget, params: { id: 99999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'authentication' do
    context 'when not authenticated' do
      before { sign_out user }
      
      it 'redirects to login for show' do
        get :show
        expect(response).to redirect_to(new_user_session_path)
      end
      
      it 'returns unauthorized for update_widget' do
        post :update_widget, params: { id: 1 }, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns unauthorized for reorder_widgets' do
        post :reorder_widgets, params: { widget_ids: [] }, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns unauthorized for refresh_widget' do
        post :refresh_widget, params: { id: 1 }, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end