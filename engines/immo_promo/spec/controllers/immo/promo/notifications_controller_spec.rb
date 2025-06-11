require 'rails_helper'

RSpec.describe Immo::Promo::NotificationsController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:notification) { create(:notification, user: user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns notifications and stats' do
      get :index
      expect(assigns(:notifications)).to be_present
      expect(assigns(:categories)).to be_present
      expect(assigns(:stats)).to be_present
    end

    it 'filters unread notifications when requested' do
      get :index, params: { unread_only: 'true' }
      expect(response).to be_successful
    end

    it 'responds to JSON format' do
      get :index, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: notification.id }
      expect(response).to be_successful
    end

    it 'marks notification as read' do
      allow(notification).to receive(:unread?).and_return(true)
      allow(notification).to receive(:mark_as_read!)
      allow(controller).to receive(:authorize_notification_access!)
      
      get :show, params: { id: notification.id }
      expect(notification).to have_received(:mark_as_read!)
    end

    it 'responds to JSON format' do
      allow(controller).to receive(:authorize_notification_access!)
      get :show, params: { id: notification.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'PATCH #mark_as_read' do
    it 'marks notification as read' do
      allow(notification).to receive(:mark_as_read!)
      allow(controller).to receive(:authorize_notification_access!)
      
      patch :mark_as_read, params: { id: notification.id }
      expect(notification).to have_received(:mark_as_read!)
    end

    it 'responds to JSON format' do
      allow(controller).to receive(:authorize_notification_access!)
      patch :mark_as_read, params: { id: notification.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'POST #mark_all_as_read' do
    it 'marks all notifications as read' do
      expect(NotificationService).to receive(:mark_all_read_for_user).with(user)
      
      post :mark_all_as_read
      expect(response).to redirect_to("/immo/promo/notifications")
      expect(flash[:notice]).to be_present
    end

    it 'responds to JSON format' do
      allow(NotificationService).to receive(:mark_all_read_for_user)
      
      post :mark_all_as_read, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'POST #bulk_mark_as_read' do
    it 'marks selected notifications as read' do
      notification_ids = ['1', '2', '3']
      expect(NotificationService).to receive(:bulk_mark_as_read).with(notification_ids, user).and_return(3)
      
      post :bulk_mark_as_read, params: { notification_ids: notification_ids }
      expect(response).to redirect_to("/immo/promo/notifications")
      expect(flash[:notice]).to include('3 notifications')
    end

    it 'responds to JSON format' do
      allow(NotificationService).to receive(:bulk_mark_as_read).and_return(2)
      
      post :bulk_mark_as_read, params: { notification_ids: ['1', '2'] }, format: :json
      expect(response).to be_successful
      
      json_response = JSON.parse(response.body)
      expect(json_response['count']).to eq(2)
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the notification' do
      allow(notification).to receive(:destroy!)
      allow(controller).to receive(:authorize_notification_access!)
      
      delete :destroy, params: { id: notification.id }
      expect(notification).to have_received(:destroy!)
      expect(response).to redirect_to("/immo/promo/notifications")
      expect(flash[:notice]).to be_present
    end

    it 'responds to JSON format' do
      allow(controller).to receive(:authorize_notification_access!)
      
      delete :destroy, params: { id: notification.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'POST #bulk_destroy' do
    it 'destroys selected notifications' do
      notification_ids = ['1', '2', '3']
      expect(NotificationService).to receive(:bulk_delete_notifications).with(notification_ids, user).and_return(3)
      
      post :bulk_destroy, params: { notification_ids: notification_ids }
      expect(response).to redirect_to("/immo/promo/notifications")
      expect(flash[:notice]).to include('3 notifications')
    end

    it 'responds to JSON format' do
      allow(NotificationService).to receive(:bulk_delete_notifications).and_return(2)
      
      post :bulk_destroy, params: { notification_ids: ['1', '2'] }, format: :json
      expect(response).to be_successful
      
      json_response = JSON.parse(response.body)
      expect(json_response['count']).to eq(2)
    end
  end

  describe 'GET #dropdown' do
    it 'returns notifications for dropdown' do
      get :dropdown
      expect(assigns(:notifications)).to be_present
      expect(assigns(:unread_count)).to be_present
    end

    it 'renders dropdown partial for HTML format' do
      get :dropdown
      expect(response).to render_template(partial: 'dropdown')
    end

    it 'responds to JSON format' do
      get :dropdown, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #urgent' do
    it 'returns urgent notifications' do
      get :urgent
      expect(assigns(:notifications)).to be_present
    end

    it 'responds to JSON format' do
      get :urgent, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #project_notifications' do
    let(:project) { create(:immo_promo_project, organization: organization) }

    it 'returns project-specific notifications' do
      get :project_notifications, params: { project_id: project.id }
      expect(assigns(:project)).to eq(project)
      expect(assigns(:notifications)).to be_present
    end

    it 'authorizes project access' do
      expect(controller).to receive(:authorize).with(project, :show?)
      get :project_notifications, params: { project_id: project.id }
    end

    it 'responds to JSON format' do
      get :project_notifications, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #stats' do
    it 'returns notification statistics' do
      get :stats, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'private methods' do
    describe '#authorize_notification_access!' do
      it 'responds to authorize_notification_access!' do
        expect(controller).to respond_to(:authorize_notification_access!, true)
      end
    end

    describe '#immo_promo_categories' do
      it 'returns ImmoPromo categories' do
        categories = controller.send(:immo_promo_categories)
        expect(categories).to include('projects', 'stakeholders', 'permits', 'budgets', 'risks')
      end
    end

    describe '#notification_json' do
      it 'responds to notification_json' do
        expect(controller).to respond_to(:notification_json, true)
      end
    end
  end
end