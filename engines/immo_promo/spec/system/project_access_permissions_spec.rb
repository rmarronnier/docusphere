require 'rails_helper'

RSpec.describe "Project Access Permissions", type: :system do
  let(:organization) { create(:organization, name: "PromoTex-#{SecureRandom.hex(4)}") }
  
  let(:admin_user) { 
    create(:user, 
      email: "admin@promotex.fr",
      role: "admin",
      organization: organization,
      permissions: { 'immo_promo:access' => true, 'immo_promo:admin' => true }
    )
  }
  
  let(:manager_user) {
    create(:user,
      email: "manager@promotex.fr", 
      role: "manager",
      organization: organization,
      permissions: { 
        'immo_promo:access' => true,
        'immo_promo:projects:create' => true,
        'immo_promo:projects:write' => true,
        'immo_promo:budget:manage' => true
      }
    )
  }
  
  let(:controller_user) {
    create(:user,
      email: "controle@promotex.fr",
      role: "manager",
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    )
  }
  
  let(:regular_user) {
    create(:user,
      email: "user@promotex.fr",
      role: "user", 
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    )
  }
  
  let(:external_user) {
    create(:user,
      email: "external@other.com",
      role: "user",
      organization: create(:organization, name: "Other Org")
    )
  }
  
  let!(:project) {
    create(:immo_promo_project,
      name: "Test Project",
      organization: organization,
      project_manager: manager_user,
      status: "studies"
    )
  }

  describe "Project List Access" do
    context "with admin user" do
      before { login_as(admin_user, scope: :user) }
      
      it "can see all projects in organization", js: true do
        visit "/immo/promo/projects"
        
        expect(page).to have_content("Test Project")
        expect(page).not_to have_content("Accès non autorisé")
        expect(page).not_to have_content("Aucun projet")
      end
    end
    
    context "with manager user" do
      before { login_as(manager_user, scope: :user) }
      
      it "can see projects they manage", js: true do
        visit "/immo/promo/projects"
        
        expect(page).to have_content("Test Project")
        expect(page).not_to have_content("Accès non autorisé")
      end
    end
    
    context "with controller user (immo_promo:access permission)" do
      before { login_as(controller_user, scope: :user) }
      
      it "can see projects due to organization-wide access", js: true do
        visit "/immo/promo/projects"
        
        expect(page).to have_content("Test Project")
        expect(page).not_to have_content("Accès non autorisé")
      end
    end
    
    context "with regular user (limited permissions)" do
      before { login_as(regular_user, scope: :user) }
      
      it "can see projects due to immo_promo:access permission", js: true do
        visit "/immo/promo/projects"
        
        expect(page).to have_content("Test Project")
        expect(page).not_to have_content("Accès non autorisé")
      end
    end
    
    context "with external user (different organization)" do
      before { login_as(external_user, scope: :user) }
      
      it "cannot see projects from other organizations", js: true do
        visit "/immo/promo/projects"
        
        expect(page).not_to have_content("Test Project")
        expect(page).to have_content("Aucun projet").or have_content("Accès non autorisé")
      end
    end
  end

  describe "Project Detail Access" do
    context "with admin user" do
      before { login_as(admin_user, scope: :user) }
      
      it "can access project details with full permissions", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_content("Test Project")
        expect(page).to have_link("Modifier")
        expect(page).to have_link("Phases")
        expect(page).to have_link("Budget")
        expect(page).to have_link("Permis")
      end
    end
    
    context "with manager user (project manager)" do
      before { login_as(manager_user, scope: :user) }
      
      it "can access project details with management permissions", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_content("Test Project")
        expect(page).to have_link("Modifier")
        expect(page).to have_link("Budget")
      end
    end
    
    context "with controller user (read-only access)" do
      before { login_as(controller_user, scope: :user) }
      
      it "can view project but with limited actions", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_content("Test Project")
        
        # Should not have management actions
        expect(page).not_to have_link("Modifier")
        expect(page).not_to have_link("Supprimer")
        
        # May still see some navigation but with restrictions
        if page.has_link?("Budget")
          click_link "Budget"
          expect(page).to have_content("non autorisé").or have_content("pas les droits")
        end
      end
    end
    
    context "with regular user" do
      before { login_as(regular_user, scope: :user) }
      
      it "can view project with basic information only", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_content("Test Project")
        expect(page).not_to have_link("Modifier")
        expect(page).not_to have_link("Supprimer")
      end
    end
    
    context "with external user" do
      before { login_as(external_user, scope: :user) }
      
      it "is denied access to project details", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_content("Accès non autorisé").or have_content("pas les droits")
        expect(page).not_to have_content("Test Project")
      end
    end
  end

  describe "Specific Feature Access" do
    let!(:budget) { create(:immo_promo_budget, project: project) }
    let!(:phase) { create(:immo_promo_phase, project: project) }
    
    describe "Budget Access" do
      context "with user having budget:manage permission" do
        before { 
          manager_user.update!(permissions: manager_user.permissions.merge('immo_promo:budget:manage' => true))
          login_as(manager_user, scope: :user) 
        }
        
        it "can access and modify budget", js: true do
          visit "/immo/promo/projects/#{project.id}/budget"
          
          expect(page).to have_content("Budget du projet")
          expect(page).not_to have_content("Accès non autorisé")
        end
      end
      
      context "with user lacking budget permissions" do
        before { login_as(regular_user, scope: :user) }
        
        it "is denied budget access", js: true do
          visit "/immo/promo/projects/#{project.id}/budget"
          
          expect(page).to have_content("Accès non autorisé").or have_content("pas les droits")
        end
      end
    end
    
    describe "Phase Management Access" do
      context "with project manager" do
        before { login_as(manager_user, scope: :user) }
        
        it "can manage phases", js: true do
          visit "/immo/promo/projects/#{project.id}/phases"
          
          expect(page).to have_content("Phases du projet")
          expect(page).not_to have_content("Accès non autorisé")
        end
      end
      
      context "with read-only user" do
        before { login_as(controller_user, scope: :user) }
        
        it "can view phases but not modify", js: true do
          visit "/immo/promo/projects/#{project.id}/phases"
          
          if page.has_content?("Phases du projet")
            expect(page).not_to have_link("Nouvelle phase")
            expect(page).not_to have_link("Modifier")
          else
            expect(page).to have_content("Accès non autorisé").or have_content("pas les droits")
          end
        end
      end
    end
  end

  describe "Project Creation Access" do
    context "with user having projects:create permission" do
      before { login_as(manager_user, scope: :user) }
      
      it "can create new projects", js: true do
        visit "/immo/promo/projects"
        
        expect(page).to have_link("Nouveau projet")
        
        click_link "Nouveau projet"
        
        expect(page).to have_content("Nouveau projet")
        expect(page).to have_field("project_name")
      end
    end
    
    context "with user lacking create permissions" do
      before { login_as(controller_user, scope: :user) }
      
      it "cannot see create project option", js: true do
        visit "/immo/promo/projects"
        
        expect(page).not_to have_link("Nouveau projet")
      end
    end
  end

  describe "Project Modification Access" do
    context "with project manager" do
      before { login_as(manager_user, scope: :user) }
      
      it "can modify their projects", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_link("Modifier")
        
        click_link "Modifier"
        
        expect(page).to have_content("Modifier le projet")
        expect(page).to have_field("project_name")
      end
    end
    
    context "with user having write permission on specific project" do
      before do
        create(:authorization,
          authorizable: project,
          user: regular_user,
          permission_level: 'write',
          granted_by: admin_user
        )
        login_as(regular_user, scope: :user)
      end
      
      it "can modify the specific project", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).to have_link("Modifier")
        
        click_link "Modifier"
        
        expect(page).to have_content("Modifier le projet")
      end
    end
    
    context "with read-only user" do
      before { login_as(controller_user, scope: :user) }
      
      it "cannot modify projects", js: true do
        visit "/immo/promo/projects/#{project.id}"
        
        expect(page).not_to have_link("Modifier")
      end
    end
  end

  describe "Error Handling and Redirects" do
    context "when accessing non-existent project" do
      before { login_as(manager_user, scope: :user) }
      
      it "shows appropriate error", js: true do
        visit "/immo/promo/projects/999999"
        
        expect(page).to have_content("introuvable").or have_content("n'existe pas")
      end
    end
    
    context "when accessing project with insufficient permissions" do
      let(:restricted_project) { 
        create(:immo_promo_project, 
          organization: organization,
          project_manager: admin_user  # Different manager
        ) 
      }
      
      before { login_as(controller_user, scope: :user) }
      
      it "handles permission denial gracefully", js: true do
        visit "/immo/promo/projects/#{restricted_project.id}/edit"
        
        expect(page).to have_content("Accès non autorisé").or have_content("pas les droits")
      end
    end
  end

  describe "Navigation Consistency" do
    before { login_as(controller_user, scope: :user) }
    
    it "maintains consistent navigation based on permissions", js: true do
      visit "/immo/promo/projects"
      
      # Navigation should be consistent across pages
      expect(page).to have_link("Projets")
      expect(page).to have_link("Tableau de bord")
      
      # User-specific navigation based on permissions
      expect(page).not_to have_link("Administration")
      expect(page).not_to have_link("Nouveau projet")
      
      # Can navigate to dashboard
      click_link "Tableau de bord"
      expect(page).to have_content("Tableau de bord")
    end
  end
end