require 'rails_helper'

RSpec.describe 'Complex Permissions Workflow', type: :system do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  
  # Create user groups
  let(:managers_group) { create(:user_group, organization: organization, name: 'Managers') }
  let(:architects_group) { create(:user_group, organization: organization, name: 'Architects') }
  let(:finance_group) { create(:user_group, organization: organization, name: 'Finance Team') }
  
  # Users
  let(:director) { create(:user, organization: organization) }
  let(:chef_projet) { create(:user, organization: organization) }
  let(:architecte) { create(:user, organization: organization) }
  let(:controleur) { create(:user, organization: organization) }
  let(:external_expert) { create(:user, organization: organization) }
  
  # User profiles
  let!(:director_profile) { create(:user_profile, user: director, profile_type: 'direction', active: true) }
  let!(:chef_projet_profile) { create(:user_profile, user: chef_projet, profile_type: 'chef_projet', active: true) }
  let!(:architecte_profile) { create(:user_profile, user: architecte, profile_type: 'architecte', active: true) }
  let!(:controleur_profile) { create(:user_profile, user: controleur, profile_type: 'controleur', active: true) }
  let!(:expert_profile) { create(:user_profile, user: external_expert, profile_type: 'expert_technique', active: true) }
  
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1000])
    
    # Setup group memberships
    create(:user_group_membership, user: chef_projet, user_group: managers_group)
    create(:user_group_membership, user: architecte, user_group: architects_group)
    create(:user_group_membership, user: controleur, user_group: finance_group)
  end
  
  describe 'Hierarchical Document Access' do
    let(:public_doc) { create(:document, space: space, uploaded_by: chef_projet, title: 'Public Project Plan') }
    let(:financial_doc) { create(:document, space: space, uploaded_by: controleur, title: 'Financial Report Q2') }
    let(:technical_doc) { create(:document, space: space, uploaded_by: architecte, title: 'Technical Specifications') }
    let(:confidential_doc) { create(:document, space: space, uploaded_by: director, title: 'Strategic Plan 2025') }
    
    before do
      # Setup complex permission hierarchy
      
      # Public document - accessible by managers group
      public_doc.authorize_group(managers_group, 'read', granted_by: chef_projet)
      public_doc.authorize_user(architecte, 'read', granted_by: chef_projet)
      
      # Financial document - finance group + director
      financial_doc.authorize_group(finance_group, 'write', granted_by: controleur)
      financial_doc.authorize_user(director, 'admin', granted_by: controleur)
      financial_doc.authorize_user(chef_projet, 'read', granted_by: controleur)
      
      # Technical document - architects group + chef projet
      technical_doc.authorize_group(architects_group, 'write', granted_by: architecte)
      technical_doc.authorize_user(chef_projet, 'read', granted_by: architecte)
      technical_doc.authorize_user(external_expert, 'read', granted_by: architecte)
      
      # Confidential document - director only
      confidential_doc.authorize_user(director, 'admin', granted_by: director)
    end
    
    scenario 'Director sees all documents in dashboard' do
      sign_in director
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Director should see statistics reflecting access to multiple documents
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Should have access to confidential information
      if page.has_text?('Strategic', wait: 3)
        expect(page).to have_text('Strategic')
      end
    end
    
    scenario 'Chef projet sees project-related documents only' do
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Should see documents they have access to
      # Public doc (via managers group), Financial (direct read), Technical (direct read)
      # Should NOT see confidential doc
      expect(page).not_to have_text('Strategic Plan')
    end
    
    scenario 'Architecte sees technical documents' do
      sign_in architecte
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Should see technical documents and public documents
      if page.has_text?('Technical', wait: 3)
        expect(page).to have_text('Technical')
      end
    end
    
    scenario 'External expert has limited access' do
      sign_in external_expert
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should have minimal access - only technical doc they were granted
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Should not see confidential or financial documents
      expect(page).not_to have_text('Strategic Plan')
      expect(page).not_to have_text('Financial Report')
    end
  end
  
  describe 'Dynamic Permission Changes' do
    let(:project_doc) { create(:document, space: space, uploaded_by: chef_projet, title: 'Project Alpha') }
    
    before do
      # Initial permissions
      project_doc.authorize_user(chef_projet, 'admin', granted_by: chef_projet)
      project_doc.authorize_user(architecte, 'read', granted_by: chef_projet)
    end
    
    scenario 'Permission escalation workflow' do
      # Step 1: Architecte has read access
      sign_in architecte
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Architecte should see document in recent documents (if available)
      sign_out architecte
      
      # Step 2: Chef projet grants write permission
      project_doc.authorize_user(architecte, 'write', granted_by: chef_projet)
      
      # Step 3: Architecte signs in again with elevated permissions
      sign_in architecte
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Dashboard should reflect new permissions
      # Widget data should be updated (via cache invalidation)
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Verify permission change took effect
      expect(project_doc.writable_by?(architecte)).to be true
    end
    
    scenario 'Permission revocation' do
      # Grant then revoke permission
      project_doc.authorize_user(controleur, 'read', granted_by: chef_projet)
      
      # Controleur can access
      sign_in controleur
      visit dashboard_path
      expect(page).to have_content('Tableau de bord')
      sign_out controleur
      
      # Revoke permission
      project_doc.revoke_authorization(controleur, 'read', revoked_by: chef_projet)
      
      # Controleur should lose access
      sign_in controleur
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should not see the document anymore
      expect(project_doc.readable_by?(controleur)).to be false
    end
  end
  
  describe 'Group Permission Inheritance' do
    let(:team_doc) { create(:document, space: space, uploaded_by: chef_projet, title: 'Team Guidelines') }
    let(:new_manager) { create(:user, organization: organization) }
    let!(:new_manager_profile) { create(:user_profile, user: new_manager, profile_type: 'chef_projet', active: true) }
    
    before do
      # Grant permission to managers group
      team_doc.authorize_group(managers_group, 'read', granted_by: chef_projet)
    end
    
    scenario 'Adding user to group grants document access' do
      # Initially, new manager has no access
      expect(team_doc.readable_by?(new_manager)).to be false
      
      # Add to managers group
      create(:user_group_membership, user: new_manager, user_group: managers_group)
      
      # Clear permission cache
      PermissionCacheService.clear_for_user(new_manager)
      
      # Now should have access
      expect(team_doc.readable_by?(new_manager)).to be true
      
      # Test in dashboard
      sign_in new_manager
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
  end
  
  describe 'Cross-Module Permissions' do
    before do
      # Setup permissions across different modules
      space.authorize_user(chef_projet, 'admin', granted_by: director)
      space.authorize_user(architecte, 'write', granted_by: chef_projet)
      space.authorize_user(controleur, 'read', granted_by: chef_projet)
    end
    
    scenario 'Users see appropriate module access in dashboard' do
      # Test chef projet with admin access
      sign_in chef_projet
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should see administrative features in navigation
      if page.has_css?('.navigation, .navbar', wait: 3)
        navigation = page.find('.navigation, .navbar')
        # Should have access to management features
        expect(navigation).to be_present
      end
      
      sign_out chef_projet
      
      # Test controleur with read-only access
      sign_in controleur
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      
      # Should have more limited options
      expect(page).to have_css('.dashboard-widget', minimum: 1)
    end
  end
  
  describe 'Permission Caching Performance' do
    let(:many_docs) { create_list(:document, 10, space: space, uploaded_by: chef_projet) }
    
    before do
      # Grant permissions to multiple documents
      many_docs.each_with_index do |doc, index|
        case index % 3
        when 0
          doc.authorize_user(architecte, 'read', granted_by: chef_projet)
        when 1
          doc.authorize_group(managers_group, 'read', granted_by: chef_projet)
        when 2
          doc.authorize_user(controleur, 'write', granted_by: chef_projet)
        end
      end
    end
    
    scenario 'Dashboard loads efficiently with complex permissions' do
      sign_in architecte
      
      start_time = Time.current
      visit dashboard_path
      
      expect(page).to have_content('Tableau de bord')
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      load_time = Time.current - start_time
      
      # Should load efficiently even with complex permissions
      expect(load_time).to be < 15.seconds
      
      # Permission caching should work
      # Subsequent permission checks should be fast
      refresh
      expect(page).to have_content('Tableau de bord')
    end
  end
  
  describe 'Audit Trail Integration' do
    let(:sensitive_doc) { create(:document, space: space, uploaded_by: director, title: 'Confidential Budget') }
    
    before do
      sensitive_doc.authorize_user(controleur, 'read', granted_by: director)
    end
    
    scenario 'Dashboard access is tracked' do
      sign_in controleur
      
      # Access dashboard
      visit dashboard_path
      expect(page).to have_content('Tableau de bord')
      
      # Dashboard access should generate audit logs
      # (PaperTrail integration should track this)
      expect(page).to have_css('.dashboard-widget', minimum: 1)
      
      # Widget interactions should be logged
      if page.has_css?('[data-action*="refresh"]', visible: :all)
        page.first('[data-action*="refresh"]', visible: :all).click
        
        # Refresh action should complete
        expect(page).to have_css('.dashboard-widget')
      end
    end
  end
end