require 'rails_helper'

RSpec.describe NotificationPreferencesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:notification_preference) { create(:notification_preference, user: user) }
  
  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns current user notification preferences' do
      notification_preference
      get :index
      expect(assigns(:preferences)).to include(notification_preference)
    end

    it 'only shows current user preferences' do
      other_user = create(:user, organization: organization)
      other_preference = create(:notification_preference, user: other_user)
      
      get :index
      expect(assigns(:preferences)).to include(notification_preference)
      expect(assigns(:preferences)).not_to include(other_preference)
    end

    it 'groups preferences by category' do
      email_pref = create(:notification_preference, user: user, notification_type: 'email', category: 'document')
      sms_pref = create(:notification_preference, user: user, notification_type: 'sms', category: 'validation')
      
      get :index
      expect(assigns(:preferences_by_category)).to have_key('document')
      expect(assigns(:preferences_by_category)).to have_key('validation')
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: notification_preference.id }
      expect(response).to be_successful
    end

    it 'assigns the requested preference' do
      get :show, params: { id: notification_preference.id }
      expect(assigns(:preference)).to eq(notification_preference)
    end

    it 'prevents access to other users preferences' do
      other_user = create(:user, organization: organization)
      other_preference = create(:notification_preference, user: other_user)
      
      expect {
        get :show, params: { id: other_preference.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new notification preference' do
      get :new
      expect(assigns(:preference)).to be_a_new(NotificationPreference)
    end

    it 'assigns the preference to current user' do
      get :new
      expect(assigns(:preference).user).to eq(user)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          notification_type: 'email',
          category: 'document',
          event_type: 'upload',
          enabled: true,
          delivery_method: 'immediate'
        }
      end

      it 'creates a new NotificationPreference' do
        expect {
          post :create, params: { notification_preference: valid_attributes }
        }.to change(NotificationPreference, :count).by(1)
      end

      it 'assigns the preference to current user' do
        post :create, params: { notification_preference: valid_attributes }
        expect(assigns(:preference).user).to eq(user)
      end

      it 'redirects to the preferences index' do
        post :create, params: { notification_preference: valid_attributes }
        expect(response).to redirect_to(notification_preferences_path)
      end

      context 'with AJAX request' do
        it 'returns JSON response' do
          post :create, params: { notification_preference: valid_attributes }, xhr: true
          expect(response).to be_successful
          expect(response.content_type).to include('application/json')
        end

        it 'includes preference data in response' do
          post :create, params: { notification_preference: valid_attributes }, xhr: true
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
          expect(json_response['preference']['notification_type']).to eq('email')
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { notification_type: '', category: '' } }

      it 'does not create a new NotificationPreference' do
        expect {
          post :create, params: { notification_preference: invalid_attributes }
        }.to change(NotificationPreference, :count).by(0)
      end

      it 'renders new template' do
        post :create, params: { notification_preference: invalid_attributes }
        expect(response).to render_template(:new)
      end

      context 'with AJAX request' do
        it 'returns error response' do
          post :create, params: { notification_preference: invalid_attributes }, xhr: true
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['errors']).to be_present
        end
      end
    end

    context 'with duplicate preference' do
      before do
        create(:notification_preference, 
               user: user, 
               notification_type: 'email', 
               category: 'document', 
               event_type: 'upload')
      end

      it 'does not create duplicate preference' do
        expect {
          post :create, params: { 
            notification_preference: { 
              notification_type: 'email', 
              category: 'document', 
              event_type: 'upload',
              enabled: true 
            } 
          }
        }.to change(NotificationPreference, :count).by(0)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: notification_preference.id }
      expect(response).to be_successful
    end

    it 'assigns the requested preference' do
      get :edit, params: { id: notification_preference.id }
      expect(assigns(:preference)).to eq(notification_preference)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) do
        { 
          enabled: false, 
          delivery_method: 'daily_digest',
          quiet_hours_start: '22:00',
          quiet_hours_end: '08:00'
        }
      end

      it 'updates the requested preference' do
        patch :update, params: { id: notification_preference.id, notification_preference: new_attributes }
        notification_preference.reload
        expect(notification_preference.enabled).to be false
        expect(notification_preference.delivery_method).to eq('daily_digest')
      end

      it 'redirects to the preferences index' do
        patch :update, params: { id: notification_preference.id, notification_preference: new_attributes }
        expect(response).to redirect_to(notification_preferences_path)
      end

      context 'with AJAX request' do
        it 'returns success JSON response' do
          patch :update, params: { id: notification_preference.id, notification_preference: new_attributes }, xhr: true
          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { delivery_method: 'invalid_method' } }

      it 'does not update the preference' do
        original_method = notification_preference.delivery_method
        patch :update, params: { id: notification_preference.id, notification_preference: invalid_attributes }
        notification_preference.reload
        expect(notification_preference.delivery_method).to eq(original_method)
      end

      it 'renders edit template' do
        patch :update, params: { id: notification_preference.id, notification_preference: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested preference' do
      notification_preference
      expect {
        delete :destroy, params: { id: notification_preference.id }
      }.to change(NotificationPreference, :count).by(-1)
    end

    it 'redirects to the preferences index' do
      delete :destroy, params: { id: notification_preference.id }
      expect(response).to redirect_to(notification_preferences_path)
    end

    context 'with AJAX request' do
      it 'returns success JSON response' do
        delete :destroy, params: { id: notification_preference.id }, xhr: true
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
      end
    end
  end

  describe 'POST #bulk_update' do
    let(:preferences) { create_list(:notification_preference, 3, user: user) }

    context 'enabling multiple preferences' do
      it 'enables all specified preferences' do
        post :bulk_update, params: { 
          action_type: 'enable',
          preference_ids: preferences.map(&:id)
        }
        
        preferences.each(&:reload)
        expect(preferences.all?(&:enabled)).to be true
      end
    end

    context 'disabling multiple preferences' do
      before { preferences.each { |p| p.update(enabled: true) } }

      it 'disables all specified preferences' do
        post :bulk_update, params: { 
          action_type: 'disable',
          preference_ids: preferences.map(&:id)
        }
        
        preferences.each(&:reload)
        expect(preferences.none?(&:enabled)).to be true
      end
    end

    context 'updating delivery method' do
      it 'updates delivery method for all preferences' do
        post :bulk_update, params: { 
          action_type: 'update_delivery',
          delivery_method: 'weekly_digest',
          preference_ids: preferences.map(&:id)
        }
        
        preferences.each(&:reload)
        expect(preferences.all? { |p| p.delivery_method == 'weekly_digest' }).to be true
      end
    end

    it 'returns success response' do
      post :bulk_update, params: { 
        action_type: 'enable',
        preference_ids: preferences.map(&:id)
      }
      expect(response).to redirect_to(notification_preferences_path)
    end

    context 'with AJAX request' do
      it 'returns JSON response' do
        post :bulk_update, params: { 
          action_type: 'enable',
          preference_ids: preferences.map(&:id)
        }, xhr: true
        
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['updated_count']).to eq(3)
      end
    end
  end

  describe 'POST #reset_to_defaults' do
    before do
      create_list(:notification_preference, 3, user: user, enabled: false)
    end

    it 'resets all preferences to default values' do
      post :reset_to_defaults
      
      user.notification_preferences.each do |pref|
        expect(pref.enabled).to be true
        expect(pref.delivery_method).to eq('immediate')
      end
    end

    it 'creates default preferences if none exist' do
      user.notification_preferences.destroy_all
      
      expect {
        post :reset_to_defaults
      }.to change(user.notification_preferences, :count)
    end

    it 'redirects to preferences index' do
      post :reset_to_defaults
      expect(response).to redirect_to(notification_preferences_path)
    end
  end

  describe 'GET #export' do
    before { create_list(:notification_preference, 3, user: user) }

    it 'exports preferences as JSON' do
      get :export, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end

    it 'exports preferences as CSV' do
      get :export, format: :csv
      expect(response).to be_successful
      expect(response.content_type).to include('text/csv')
    end

    it 'includes all user preferences in export' do
      get :export, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response['preferences'].count).to eq(3)
    end
  end

  describe 'POST #import' do
    let(:import_data) do
      {
        preferences: [
          {
            notification_type: 'email',
            category: 'document',
            event_type: 'upload',
            enabled: true,
            delivery_method: 'immediate'
          },
          {
            notification_type: 'sms',
            category: 'validation',
            event_type: 'completed',
            enabled: false,
            delivery_method: 'daily_digest'
          }
        ]
      }
    end

    it 'imports preferences from JSON data' do
      expect {
        post :import, params: import_data
      }.to change(user.notification_preferences, :count).by(2)
    end

    it 'overwrites existing preferences' do
      existing = create(:notification_preference, 
                       user: user, 
                       notification_type: 'email', 
                       category: 'document', 
                       event_type: 'upload',
                       enabled: false)
      
      post :import, params: import_data
      existing.reload
      expect(existing.enabled).to be true
    end

    it 'returns success response' do
      post :import, params: import_data
      expect(response).to redirect_to(notification_preferences_path)
    end
  end

  describe 'authentication' do
    before { sign_out user }

    it 'redirects to login for index' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for show' do
      get :show, params: { id: notification_preference.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end