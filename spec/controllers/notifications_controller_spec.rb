require 'rails_helper'

RSpec.describe NotificationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:document) { create(:document, organization: organization, uploaded_by: user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    let!(:notification1) { create(:notification, user: user, notification_type: 'document_shared') }
    let!(:notification2) { create(:notification, user: user, notification_type: 'project_created') }
    let!(:other_user_notification) { create(:notification) }

    it 'returns successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns user notifications' do
      get :index
      expect(assigns(:notifications)).to include(notification1, notification2)
      expect(assigns(:notifications)).not_to include(other_user_notification)
    end

    it 'assigns categories and stats' do
      get :index
      expect(assigns(:categories)).to eq(Notification.categories)
      expect(assigns(:stats)).to be_a(Hash)
    end

    context 'with category filter' do
      it 'filters by category' do
        get :index, params: { category: 'documents' }
        expect(assigns(:notifications)).to include(notification1)
        expect(assigns(:notifications)).not_to include(notification2)
      end
    end

    context 'with unread_only filter' do
      let!(:read_notification) { create(:notification, user: user, read_at: 1.hour.ago) }

      it 'shows only unread notifications' do
        get :index, params: { unread_only: 'true' }
        expect(assigns(:notifications)).to include(notification1, notification2)
        expect(assigns(:notifications)).not_to include(read_notification)
      end
    end

    context 'JSON request' do
      it 'returns JSON response' do
        get :index, format: :json
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'GET #show' do
    let(:notification) { create(:notification, user: user, read_at: nil) }

    it 'returns successful response' do
      get :show, params: { id: notification.id }
      expect(response).to be_successful
    end

    it 'marks notification as read' do
      expect {
        get :show, params: { id: notification.id }
      }.to change { notification.reload.read_at }.from(nil)
    end

    it 'does not mark already read notification' do
      notification.update!(read_at: 1.hour.ago)
      original_time = notification.read_at
      
      get :show, params: { id: notification.id }
      expect(notification.reload.read_at).to eq(original_time)
    end

    context 'when notification belongs to other user' do
      let(:other_notification) { create(:notification) }

      it 'raises not found error' do
        expect {
          get :show, params: { id: other_notification.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'JSON request' do
      it 'returns JSON response' do
        get :show, params: { id: notification.id }, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(notification.id)
        expect(json_response['title']).to eq(notification.title)
      end
    end
  end

  describe 'PATCH #mark_as_read' do
    let(:notification) { create(:notification, user: user, read_at: nil) }

    it 'marks notification as read' do
      expect {
        patch :mark_as_read, params: { id: notification.id }
      }.to change { notification.reload.read_at }.from(nil)
    end

    it 'redirects back' do
      patch :mark_as_read, params: { id: notification.id }
      expect(response).to redirect_to(notifications_path)
    end

    context 'JSON request' do
      it 'returns JSON response' do
        patch :mark_as_read, params: { id: notification.id }, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['read']).to be true
      end
    end
  end

  describe 'PATCH #mark_all_as_read' do
    let!(:unread1) { create(:notification, user: user, read_at: nil) }
    let!(:unread2) { create(:notification, user: user, read_at: nil) }

    it 'marks all notifications as read' do
      patch :mark_all_as_read
      
      expect(unread1.reload.read_at).to be_present
      expect(unread2.reload.read_at).to be_present
    end

    it 'redirects with success message' do
      patch :mark_all_as_read
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to include('marquées comme lues')
    end

    context 'JSON request' do
      it 'returns success response' do
        patch :mark_all_as_read, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end
  end

  describe 'PATCH #bulk_mark_as_read' do
    let!(:notification1) { create(:notification, user: user, read_at: nil) }
    let!(:notification2) { create(:notification, user: user, read_at: nil) }

    it 'marks selected notifications as read' do
      patch :bulk_mark_as_read, params: { notification_ids: [notification1.id, notification2.id] }
      
      expect(notification1.reload.read_at).to be_present
      expect(notification2.reload.read_at).to be_present
    end

    it 'redirects with count message' do
      patch :bulk_mark_as_read, params: { notification_ids: [notification1.id, notification2.id] }
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to include('2 notifications')
    end

    context 'JSON request' do
      it 'returns count in response' do
        patch :bulk_mark_as_read, params: { notification_ids: [notification1.id, notification2.id] }, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['count']).to eq(2)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:notification) { create(:notification, user: user) }

    it 'destroys notification' do
      expect {
        delete :destroy, params: { id: notification.id }
      }.to change(Notification, :count).by(-1)
    end

    it 'redirects with success message' do
      delete :destroy, params: { id: notification.id }
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to include('supprimée')
    end

    context 'JSON request' do
      it 'returns success response' do
        delete :destroy, params: { id: notification.id }, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end
  end

  describe 'DELETE #bulk_destroy' do
    let!(:notification1) { create(:notification, user: user) }
    let!(:notification2) { create(:notification, user: user) }

    it 'destroys selected notifications' do
      expect {
        delete :bulk_destroy, params: { notification_ids: [notification1.id, notification2.id] }
      }.to change(Notification, :count).by(-2)
    end

    it 'redirects with count message' do
      delete :bulk_destroy, params: { notification_ids: [notification1.id, notification2.id] }
      expect(response).to redirect_to(notifications_path)
      expect(flash[:notice]).to include('2 notifications')
    end

    context 'JSON request' do
      it 'returns count in response' do
        delete :bulk_destroy, params: { notification_ids: [notification1.id, notification2.id] }, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['count']).to eq(2)
      end
    end
  end

  describe 'GET #dropdown' do
    let!(:recent_notifications) { create_list(:notification, 5, user: user) }

    it 'returns successful response' do
      get :dropdown
      expect(response).to be_successful
    end

    it 'assigns recent notifications and unread count' do
      get :dropdown
      expect(assigns(:notifications).count).to eq(5)
      expect(assigns(:unread_count)).to eq(5)
    end

    context 'JSON request' do
      it 'returns notifications and count' do
        get :dropdown, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['notifications'].count).to eq(5)
        expect(json_response['unread_count']).to eq(5)
      end
    end
  end

  describe 'GET #urgent' do
    let!(:urgent_notification) { create(:notification, user: user, notification_type: 'budget_exceeded', read_at: nil) }
    let!(:normal_notification) { create(:notification, user: user, notification_type: 'document_shared') }

    it 'returns successful response' do
      get :urgent
      expect(response).to be_successful
    end

    it 'assigns only urgent notifications' do
      get :urgent
      expect(assigns(:notifications)).to include(urgent_notification)
      expect(assigns(:notifications)).not_to include(normal_notification)
    end

    context 'JSON request' do
      it 'returns urgent notifications' do
        get :urgent, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response.first['urgent']).to be true
      end
    end
  end

  describe 'GET #stats' do
    let!(:unread_notification) { create(:notification, user: user, read_at: nil) }
    let!(:read_notification) { create(:notification, user: user, read_at: 1.hour.ago) }

    context 'JSON request' do
      it 'returns user stats' do
        get :stats, format: :json
        expect(response).to be_successful
        
        json_response = JSON.parse(response.body)
        expect(json_response['total']).to eq(2)
        expect(json_response['unread']).to eq(1)
        expect(json_response['by_category']).to be_a(Hash)
      end
    end
  end

  context 'when user is not authenticated' do
    before do
      sign_out user
    end

    it 'redirects to login' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end