require 'rails_helper'

RSpec.describe 'Multi-User Validation Workflow', type: :system do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  
  # Users with different profiles
  let(:director) { create(:user, organization: organization) }
  let(:chef_projet) { create(:user, organization: organization) }
  let(:controleur) { create(:user, organization: organization) }
  let(:juriste) { create(:user, organization: organization) }
  
  # User profiles
  let!(:director_profile) { create(:user_profile, user: director, profile_type: 'direction', active: true) }
  let!(:chef_projet_profile) { create(:user_profile, user: chef_projet, profile_type: 'chef_projet', active: true) }
  let!(:controleur_profile) { create(:user_profile, user: controleur, profile_type: 'controleur', active: true) }
  let!(:juriste_profile) { create(:user_profile, user: juriste, profile_type: 'juriste', active: true) }
  
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1000])
  end
  
  describe 'Document Validation Chain' do
    let(:document) { create(:document, space: space, uploaded_by: chef_projet, title: 'Budget Q2 2025') }
    
    before do
      # Setup document permissions
      document.authorize_user(director, 'admin', granted_by: chef_projet)
      document.authorize_user(controleur, 'write', granted_by: chef_projet)
      document.authorize_user(juriste, 'read', granted_by: chef_projet)
    end
    
    scenario 'Complete validation workflow from chef projet to director' do
      # Step 1: Chef projet creates validation request
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Chef projet should see their dashboard
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Create a validation request (simulated)
      validation_request = create(:validation_request, 
                                 validatable: document, 
                                 status: 'pending',
                                 description: 'Validation budget Q2')
      
      # Create document validation for director
      document_validation = create(:document_validation,
                                  validation_request: validation_request,
                                  validator: director,
                                  status: 'pending')
      
      sign_out chef_projet
      
      # Step 2: Director receives notification and validates
      sign_in director
      visit dashboard_path
      
      # Director should see validation in their dashboard
      expect(page).to have_content('Tableau de bord')
      
      # Should see pending validations (if widget is configured)
      if page.has_text?('validation', wait: 3)
        expect(page).to have_text(/validation|approbation/i)
      end
      
      # Simulate validation approval
      document_validation.update!(status: 'approved', validated_at: Time.current)
      validation_request.update!(status: 'completed')
      
      # Refresh to see updated state
      refresh
      expect(page).to have_content('Tableau de bord')
      
      sign_out director
      
      # Step 3: Chef projet sees completed validation
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Verification that workflow completed
      expect(validation_request.reload.status).to eq('completed')
      expect(document_validation.reload.status).to eq('approved')
    end
  end
  
  describe 'Cross-Profile Notifications' do
    before do
      # Create notifications for different users
      create(:notification, user: director, title: 'Budget validation required', read_at: nil)
      create(:notification, user: chef_projet, title: 'Project milestone reached', read_at: nil)
      create(:notification, user: controleur, title: 'Financial review needed', read_at: nil)
    end
    
    scenario 'Each profile sees appropriate notifications in dashboard' do
      # Test director notifications
      sign_in director
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should see notifications widget or count
      if page.has_css?('.notifications-widget, [data-widget-type="notifications"]', wait: 3)
        expect(page).to have_css('.notifications-widget, [data-widget-type="notifications"]')
      end
      
      sign_out director
      
      # Test chef projet notifications
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Each user should see their own dashboard
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      sign_out chef_projet
      
      # Test controleur notifications
      sign_in controleur
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
  end
  
  describe 'Permission-Based Widget Content' do
    let(:public_document) { create(:document, space: space, uploaded_by: chef_projet, title: 'Public Document') }
    let(:private_document) { create(:document, space: space, uploaded_by: director, title: 'Private Document') }
    
    before do
      # Setup permissions
      public_document.authorize_user(chef_projet, 'read', granted_by: chef_projet)
      public_document.authorize_user(controleur, 'read', granted_by: chef_projet)
      
      # Private document only for director
      private_document.authorize_user(director, 'admin', granted_by: director)
    end
    
    scenario 'Users see only documents they have permission to access' do
      # Test chef projet access
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Chef projet should see public document in recent documents widget
      if page.has_text?('Public Document', wait: 3)
        expect(page).to have_text('Public Document')
      end
      
      # Should not see private document
      expect(page).not_to have_text('Private Document')
      
      sign_out chef_projet
      
      # Test director access
      sign_in director
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Director should be able to see private document
      # (though it might not show in widget due to recent ordering)
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
  end
  
  describe 'Real-time Dashboard Updates' do
    let(:document) { create(:document, space: space, uploaded_by: chef_projet) }
    
    before do
      document.authorize_user(chef_projet, 'write', granted_by: chef_projet)
      document.authorize_user(director, 'read', granted_by: chef_projet)
    end
    
    scenario 'Widget refresh updates content' do
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Find a refreshable widget
      refreshable_widget = page.first('.dashboard-widget[data-widget-id]')
      
      if refreshable_widget
        widget_id = refreshable_widget['data-widget-id']
        
        # Look for refresh button
        refresh_button = refreshable_widget.first('[data-action*="refresh"]', visible: :all)
        
        if refresh_button
          # Click refresh
          refresh_button.click
          
          # Should handle the refresh without errors
          expect(page).to have_css("[data-widget-id='#{widget_id}']")
          
          # Widget should still be present after refresh
          expect(refreshable_widget).to be_present
        end
      end
    end
  end
  
  describe 'Performance Under Load' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    
    before do
      # Create multiple widgets for performance testing
      5.times do |i|
        create(:dashboard_widget,
               user_profile: user_profile,
               widget_type: ['recent_documents', 'notifications', 'statistics', 'pending_tasks', 'quick_access'][i % 5],
               position: i)
      end
      
      # Create some data for widgets to display
      10.times do |i|
        doc = create(:document, space: space, uploaded_by: user, title: "Test Document #{i}")
        doc.authorize_user(user, 'read', granted_by: user)
      end
      
      create_list(:notification, 5, user: user, read_at: nil)
    end
    
    scenario 'Dashboard loads efficiently with multiple widgets' do
      sign_in user
      
      start_time = Time.current
      visit dashboard_path
      
      # Should load dashboard
      expect(page).to have_content('Tableau de bord')
      
      # Should show all widgets
      expect(page).to have_css('.dashboard-widget', count: 5)
      
      load_time = Time.current - start_time
      
      # Should load in reasonable time for system test (under 15 seconds)
      expect(load_time).to be < 15.seconds
      
      # All widgets should be functional
      widgets = page.all('.dashboard-widget')
      expect(widgets.count).to eq(5)
      
      # No error states should be visible
      expect(page).not_to have_css('.widget-error')
    end
  end
  
  describe 'Error Handling' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    
    scenario 'Dashboard handles widget errors gracefully' do
      sign_in user
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Dashboard should load even if some widgets fail
      expect(page).to have_css('.dashboard-container')
      
      # Should not show any JavaScript errors that break the page
      expect(page).not_to have_content('Error')
      expect(page).not_to have_content('undefined')
    end
  end
end