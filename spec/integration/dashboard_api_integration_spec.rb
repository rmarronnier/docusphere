require 'rails_helper'

RSpec.describe 'Dashboard API Integration', type: :request do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  
  describe 'Profile-based Dashboard Personalization' do
    let(:director) { create(:user, organization: organization) }
    let(:chef_projet) { create(:user, organization: organization) }
    let(:controleur) { create(:user, organization: organization) }
    
    let!(:director_profile) { create(:user_profile, user: director, profile_type: 'direction', active: true) }
    let!(:chef_projet_profile) { create(:user_profile, user: chef_projet, profile_type: 'chef_projet', active: true) }
    let!(:controleur_profile) { create(:user_profile, user: controleur, profile_type: 'controleur', active: true) }
    
    before do
      # Create basic widgets for testing
      create(:dashboard_widget, user_profile: director_profile, widget_type: 'statistics', position: 1)
      create(:dashboard_widget, user_profile: chef_projet_profile, widget_type: 'recent_documents', position: 1)
      create(:dashboard_widget, user_profile: controleur_profile, widget_type: 'notifications', position: 1)
    end
    
    context 'Director Dashboard' do
      before { sign_in director }
      
      it 'returns personalized dashboard for direction profile' do
        get dashboard_path, headers: { 'Host' => 'localhost' }, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Tableau de bord')
        
        # Should contain direction-specific content
        expect(assigns(:dashboard_data)).to be_present
        expect(assigns(:dashboard_data)[:widgets]).to be_an(Array)
        expect(assigns(:dashboard_data)[:widgets].size).to be >= 1
      end
      
      it 'includes appropriate metrics for direction profile' do
        get dashboard_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
        
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:metrics]).to be_present
        expect(dashboard_data[:actions]).to be_an(Array)
        expect(dashboard_data[:navigation]).to be_an(Array)
      end
    end
    
    context 'Chef Projet Dashboard' do
      before { sign_in chef_projet }
      
      it 'returns personalized dashboard for chef projet profile' do
        get dashboard_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
        
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:widgets]).to be_an(Array)
        expect(dashboard_data[:widgets].size).to be >= 1
        
        # Verify project-specific widgets
        widget_types = dashboard_data[:widgets].map { |w| w[:type] }
        expect(widget_types).to include('recent_documents')
      end
    end
    
    context 'Controleur Dashboard' do
      before { sign_in controleur }
      
      it 'returns personalized dashboard for controleur profile' do
        get dashboard_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
        
        dashboard_data = assigns(:dashboard_data)
        expect(dashboard_data[:widgets]).to be_an(Array)
        expect(dashboard_data[:widgets].size).to be >= 1
        
        # Verify finance-specific widgets
        widget_types = dashboard_data[:widgets].map { |w| w[:type] }
        expect(widget_types).to include('notifications')
      end
    end
  end
  
  describe 'Widget Personalization API' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    let!(:widget1) { create(:dashboard_widget, user_profile: user_profile, widget_type: 'statistics', position: 1) }
    let!(:widget2) { create(:dashboard_widget, user_profile: user_profile, widget_type: 'notifications', position: 2) }
    let!(:widget3) { create(:dashboard_widget, user_profile: user_profile, widget_type: 'recent_documents', position: 3) }
    
    before { sign_in user }
    
    describe 'Widget Reordering' do
      it 'reorders widgets successfully' do
        new_order = [widget3.id, widget1.id, widget2.id]
        
        post reorder_widgets_dashboard_path, params: { widget_ids: new_order }, as: :json
        
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['status']).to eq('success')
        
        # Verify new positions
        expect(widget1.reload.position).to eq(2)
        expect(widget2.reload.position).to eq(3)
        expect(widget3.reload.position).to eq(1)
      end
      
      it 'ignores widgets from other users' do
        other_user = create(:user, organization: organization)
        other_profile = create(:user_profile, user: other_user, profile_type: 'direction', active: true)
        other_widget = create(:dashboard_widget, user_profile: other_profile)
        
        original_position = other_widget.position
        new_order = [widget1.id, other_widget.id, widget2.id]
        
        post reorder_widgets_dashboard_path, params: { widget_ids: new_order }, as: :json
        
        expect(response).to have_http_status(:success)
        
        # Other user's widget should not be affected
        expect(other_widget.reload.position).to eq(original_position)
        
        # Own widgets should be reordered
        expect(widget1.reload.position).to eq(1)
        expect(widget2.reload.position).to eq(2)
      end
    end
    
    describe 'Widget Resize' do
      it 'updates widget dimensions' do
        patch update_widget_dashboard_path(widget1), 
              params: { widget: { width: 3, height: 2 } }, 
              as: :json
        
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['status']).to eq('success')
        
        widget1.reload
        expect(widget1.width).to eq(3)
        expect(widget1.height).to eq(2)
      end
      
      it 'validates widget dimensions' do
        patch update_widget_dashboard_path(widget1), 
              params: { widget: { width: 5, height: 5 } }, 
              as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['status']).to eq('error')
      end
      
      it 'updates widget configuration' do
        patch update_widget_dashboard_path(widget1), 
              params: { 
                widget: { 
                  config: { 
                    refresh_interval: 300,
                    show_header: false 
                  } 
                } 
              }, 
              as: :json
        
        expect(response).to have_http_status(:success)
        
        widget1.reload
        expect(widget1.config['refresh_interval']).to eq(300)
        expect(widget1.config['show_header']).to eq(false)
      end
    end
    
    describe 'Widget Refresh' do
      it 'refreshes widget data' do
        post refresh_widget_dashboard_path(widget1), as: :json
        
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['status']).to eq('success')
        expect(response.parsed_body['widget']).to be_present
        
        # Should update last_refreshed_at timestamp
        widget1.reload
        expect(widget1.config['last_refreshed_at']).to be_present
        expect(Time.parse(widget1.config['last_refreshed_at'])).to be_within(1.second).of(Time.current)
      end
      
      it 'returns 404 for non-existent widget' do
        post refresh_widget_dashboard_path(99999), as: :json
        
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['status']).to eq('error')
      end
      
      it 'returns 404 for other user\'s widget' do
        other_user = create(:user, organization: organization)
        other_profile = create(:user_profile, user: other_user, profile_type: 'direction', active: true)
        other_widget = create(:dashboard_widget, user_profile: other_profile)
        
        post refresh_widget_dashboard_path(other_widget), as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'Cache Performance Integration' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    
    before do
      sign_in user
      
      # Create some data for widgets to cache
      documents = create_list(:document, 5, space: space, uploaded_by: user)
      documents.each { |doc| doc.authorize_user(user, 'read', granted_by: user) }
      
      create_list(:notification, 3, user: user, read_at: nil)
      
      # Create widgets
      create(:dashboard_widget, user_profile: user_profile, widget_type: 'recent_documents', position: 1)
      create(:dashboard_widget, user_profile: user_profile, widget_type: 'notifications', position: 2)
      create(:dashboard_widget, user_profile: user_profile, widget_type: 'statistics', position: 3)
    end
    
    it 'caches widget data effectively' do
      # Clear cache
      Rails.cache.clear
      
      # First request should populate cache
      start_time = Time.current
      get dashboard_path
      first_load_time = Time.current - start_time
      
      expect(response).to have_http_status(:success)
      
      # Second request should use cache and be faster
      start_time = Time.current
      get dashboard_path
      second_load_time = Time.current - start_time
      
      expect(response).to have_http_status(:success)
      expect(second_load_time).to be < first_load_time
    end
    
    it 'invalidates cache when widget is updated' do
      # Populate cache
      get dashboard_path
      widget = user_profile.dashboard_widgets.first
      
      # Update widget (should invalidate cache)
      patch update_widget_dashboard_path(widget), 
            params: { widget: { width: 2 } }, 
            as: :json
      
      expect(response).to have_http_status(:success)
      
      # Next dashboard load should get fresh data
      get dashboard_path
      expect(response).to have_http_status(:success)
      
      # Verify widget shows updated dimensions
      dashboard_data = assigns(:dashboard_data)
      updated_widget = dashboard_data[:widgets].find { |w| w[:id] == widget.id }
      expect(updated_widget[:width]).to eq(2)
    end
  end
  
  describe 'Permission-based Widget Content' do
    let(:director) { create(:user, organization: organization) }
    let(:chef_projet) { create(:user, organization: organization) }
    
    let!(:director_profile) { create(:user_profile, user: director, profile_type: 'direction', active: true) }
    let!(:chef_projet_profile) { create(:user_profile, user: chef_projet, profile_type: 'chef_projet', active: true) }
    
    let(:public_doc) { create(:document, space: space, uploaded_by: chef_projet, title: 'Public Document') }
    let(:private_doc) { create(:document, space: space, uploaded_by: director, title: 'Private Document') }
    
    before do
      # Setup permissions
      public_doc.authorize_user(chef_projet, 'read', granted_by: chef_projet)
      public_doc.authorize_user(director, 'read', granted_by: chef_projet)
      
      private_doc.authorize_user(director, 'admin', granted_by: director)
      
      # Create recent documents widgets
      create(:dashboard_widget, user_profile: director_profile, widget_type: 'recent_documents', position: 1)
      create(:dashboard_widget, user_profile: chef_projet_profile, widget_type: 'recent_documents', position: 1)
    end
    
    it 'shows different documents based on user permissions' do
      # Director should see both documents
      sign_in director
      get dashboard_path
      
      expect(response).to have_http_status(:success)
      
      director_widgets = assigns(:dashboard_data)[:widgets]
      recent_docs_widget = director_widgets.find { |w| w[:type] == 'recent_documents' }
      expect(recent_docs_widget[:data][:total]).to be >= 2
      
      sign_out director
      
      # Chef projet should only see public document
      sign_in chef_projet
      get dashboard_path
      
      expect(response).to have_http_status(:success)
      
      chef_widgets = assigns(:dashboard_data)[:widgets]
      recent_docs_widget = chef_widgets.find { |w| w[:type] == 'recent_documents' }
      expect(recent_docs_widget[:data][:total]).to be >= 1
      
      # Verify chef projet cannot see private document
      doc_titles = recent_docs_widget[:data][:content].map { |doc| doc[:name] }
      expect(doc_titles).not_to include('Private Document')
    end
  end
  
  describe 'Error Handling' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    
    before { sign_in user }
    
    it 'handles missing user profile gracefully' do
      user_profile.destroy
      
      get dashboard_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Tableau de bord')
      
      # Should create default profile
      expect(user.reload.active_profile).to be_present
    end
    
    it 'handles widget errors gracefully' do
      # Create a widget that might fail
      widget = create(:dashboard_widget, user_profile: user_profile, widget_type: 'non_existent_type')
      
      get dashboard_path
      
      expect(response).to have_http_status(:success)
      
      # Dashboard should load even with broken widgets
      dashboard_data = assigns(:dashboard_data)
      expect(dashboard_data[:widgets]).to be_an(Array)
    end
  end
  
  describe 'Authentication and Authorization' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    let(:widget) { create(:dashboard_widget, user_profile: user_profile) }
    
    context 'when not authenticated' do
      it 'redirects to login for dashboard' do
        get dashboard_path, headers: { 'Host' => 'localhost' }
        expect(response).to redirect_to(new_user_session_path)
      end
      
      it 'returns unauthorized for widget operations' do
        post refresh_widget_dashboard_path(widget), as: :json
        expect(response).to have_http_status(:unauthorized)
        
        patch update_widget_dashboard_path(widget), 
              params: { widget: { width: 2 } }, 
              as: :json
        expect(response).to have_http_status(:unauthorized)
        
        post reorder_widgets_dashboard_path, 
             params: { widget_ids: [widget.id] }, 
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'when authenticated' do
      before { sign_in user }
      
      it 'allows access to dashboard' do
        get dashboard_path, headers: { 'Host' => 'localhost' }
        expect(response).to have_http_status(:success)
      end
      
      it 'allows widget operations on own widgets' do
        post refresh_widget_dashboard_path(widget), as: :json
        expect(response).to have_http_status(:success)
        
        patch update_widget_dashboard_path(widget), 
              params: { widget: { width: 2 } }, 
              as: :json
        expect(response).to have_http_status(:success)
      end
    end
  end
end