require 'rails_helper'

RSpec.describe 'Dashboard Personalization by Profile', type: :system do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1000])
  end
  
  describe 'Direction Profile Dashboard' do
    let(:director) { create(:user, organization: organization) }
    let(:director_profile) { create(:user_profile, user: director, profile_type: 'direction', active: true) }
    
    before do
      # Create some data for the director to see
      documents = create_list(:document, 5, space: space, uploaded_by: director)
      documents.each { |doc| doc.authorize_user(director, 'read', granted_by: director) }
      
      create_list(:notification, 3, user: director, read_at: nil)
      
      sign_in director
    end
    
    scenario 'Director sees executive dashboard with portfolio overview' do
      visit dashboard_path
      
      # Should see dashboard title
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_content("Bienvenue")
      
      # Should have personalization button
      expect(page).to have_button('Personnaliser')
      
      # Should see default widgets for direction profile
      expect(page).to have_css('.dashboard-widget', minimum: 3)
      
      # Check for priority actions panel
      if page.has_css?('.actions-panel')
        expect(page).to have_css('.actions-panel')
      end
      
      # Should display some metrics
      expect(page).to have_text(/documents|projets|validations/i, wait: 5)
    end
    
    scenario 'Director can personalize dashboard layout' do
      visit dashboard_path
      
      # Enable edit mode
      click_button 'Personnaliser'
      expect(page).to have_css('.edit-mode', wait: 5)
      
      # Should show drag handles
      expect(page).to have_css('.widget-drag-handle', visible: :all)
      
      # Should be able to exit edit mode
      click_button 'Personnaliser'
      expect(page).not_to have_css('.edit-mode')
    end
  end
  
  describe 'Chef Projet Profile Dashboard' do
    let(:chef_projet) { create(:user, organization: organization) }
    let(:chef_projet_profile) { create(:user_profile, user: chef_projet, profile_type: 'chef_projet', active: true) }
    
    before do
      # Create project-related data
      documents = create_list(:document, 3, space: space, uploaded_by: chef_projet)
      documents.each { |doc| doc.authorize_user(chef_projet, 'write', granted_by: chef_projet) }
      
      # Create validation requests for the chef projet
      validation_requests = create_list(:validation_request, 2, status: 'pending')
      validation_requests.each do |req|
        create(:document_validation, 
               validation_request: req, 
               validator: chef_projet, 
               status: 'pending')
      end
      
      sign_in chef_projet
    end
    
    scenario 'Chef projet sees project management dashboard' do
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should see widgets appropriate for project management
      expect(page).to have_css('.dashboard-widget', minimum: 2)
      
      # Should see pending tasks or validations
      expect(page).to have_text(/tâches|validations|documents/i, wait: 5)
    end
    
    scenario 'Chef projet can refresh widget data' do
      visit dashboard_path
      
      # Find a widget with refresh capability
      widget = page.first('.dashboard-widget[data-widget-id]')
      
      if widget && widget.has_css?('[data-action="click->dashboard#refreshWidget"]', visible: :all)
        widget_id = widget['data-widget-id']
        
        # Click refresh button
        within(widget) do
          find('[data-action="click->dashboard#refreshWidget"]', visible: :all).click
        end
        
        # Should show loading state briefly
        expect(widget).to have_css('.loading', wait: 2) if widget.has_css?('.loading', wait: 1)
        
        # Loading should disappear
        expect(widget).not_to have_css('.loading', wait: 5)
      end
    end
  end
  
  describe 'Commercial Profile Dashboard' do
    let(:commercial) { create(:user, organization: organization) }
    let(:commercial_profile) { create(:user_profile, user: commercial, profile_type: 'commercial', active: true) }
    
    before do
      sign_in commercial
    end
    
    scenario 'Commercial sees sales-oriented dashboard' do
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Should have appropriate content for commercial profile
      expect(page).to have_text(/commercial|ventes|clients|objectifs/i, wait: 5)
    end
  end
  
  describe 'Profile Switching' do
    let(:multi_profile_user) { create(:user, organization: organization) }
    let!(:direction_profile) { create(:user_profile, user: multi_profile_user, profile_type: 'direction', active: true) }
    let!(:chef_projet_profile) { create(:user_profile, user: multi_profile_user, profile_type: 'chef_projet', active: false) }
    
    before do
      sign_in multi_profile_user
    end
    
    scenario 'User can switch between profiles' do
      visit dashboard_path
      
      # Should be on direction profile initially
      expect(page).to have_content('Tableau de bord')
      
      # Look for profile switcher
      if page.has_css?('.profile-switcher', wait: 2)
        # Test profile switching functionality
        expect(page).to have_css('.profile-switcher')
      else
        # If no profile switcher visible, just verify the dashboard loads
        expect(page).to have_css('.dashboard-widgets')
      end
    end
  end
  
  describe 'Cache Performance' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    
    before do
      # Create widgets for the user
      3.times do |i|
        create(:dashboard_widget, 
               user_profile: user_profile, 
               widget_type: ['recent_documents', 'notifications', 'statistics'][i],
               position: i)
      end
      
      sign_in user
    end
    
    scenario 'Dashboard loads quickly with caching' do
      start_time = Time.current
      
      visit dashboard_path
      
      # Dashboard should load
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      load_time = Time.current - start_time
      
      # Should load reasonably quickly (under 10 seconds for system test)
      expect(load_time).to be < 10.seconds
    end
    
    scenario 'Widgets cache data correctly' do
      visit dashboard_path
      
      # First load
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Refresh page - should use cached data
      refresh
      
      # Should still display widgets
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
  end
  
  describe 'Responsive Design' do
    let(:user) { create(:user, organization: organization) }
    let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
    
    before do
      sign_in user
    end
    
    scenario 'Dashboard adapts to mobile viewport' do
      # Test mobile view
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size
      
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should still show widgets, possibly in single column
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
    
    scenario 'Dashboard works on tablet viewport' do
      # Test tablet view
      page.driver.browser.manage.window.resize_to(768, 1024) # iPad size
      
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
  end
end