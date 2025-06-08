require 'rails_helper'

RSpec.describe "User Workflows", type: :system do
  let(:organization) { create(:organization, name: "PromoTex-#{SecureRandom.hex(4)}") }
  
  # Users from demo seeds
  let(:admin_user) { 
    create(:user, 
      email: "admin@promotex.fr",
      first_name: "Jean",
      last_name: "Dupont",
      role: "admin",
      organization: organization,
      permissions: { 'immo_promo:access' => true, 'immo_promo:admin' => true }
    )
  }
  
  let(:manager_user) {
    create(:user,
      email: "manager@promotex.fr", 
      first_name: "Marie",
      last_name: "Martin",
      role: "manager",
      organization: organization,
      permissions: { 
        'immo_promo:access' => true,
        'immo_promo:projects:create' => true,
        'immo_promo:projects:write' => true,
        'immo_promo:budget:manage' => true,
        'immo_promo:permits:manage' => true
      }
    )
  }
  
  let(:controller_user) {
    create(:user,
      email: "controle@promotex.fr",
      first_name: "Anne", 
      last_name: "Moreau",
      role: "manager",
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    )
  }
  
  let(:architect_user) {
    create(:user,
      email: "architecte@promotex.fr",
      first_name: "Pierre",
      last_name: "Leroy", 
      role: "user",
      organization: organization,
      permissions: { 
        'immo_promo:access' => true,
        'immo_promo:projects:write' => true 
      }
    )
  }
  
  let(:finance_user) {
    create(:user,
      email: "finance@promotex.fr",
      first_name: "Sophie",
      last_name: "Bernard",
      role: "user", 
      organization: organization,
      permissions: { 
        'immo_promo:access' => true,
        'immo_promo:financial:read' => true,
        'immo_promo:budget:manage' => true
      }
    )
  }
  
  # Projects from demo seeds
  let!(:villa_project) {
    create(:immo_promo_project,
      name: "Villa Les Oliviers",
      description: "Projet de villa individuelle haut de gamme",
      project_type: "residential",
      status: "planning",
      total_budget_cents: 180000000,
      city: "Aix-en-Provence",
      address: "123 Chemin des Oliviers",
      total_area: 250,
      total_units: 1,
      expected_completion_date: 18.months.from_now,
      reference_number: "VLO-2025-001",
      organization: organization,
      project_manager: manager_user
    )
  }
  
  let!(:residence_project) {
    create(:immo_promo_project,
      name: "Résidence Harmony",
      description: "Résidence de 24 appartements avec espaces verts",
      project_type: "residential", 
      status: "construction",
      total_budget_cents: 450000000,
      city: "Lyon",
      address: "45 Avenue de la République",
      total_area: 1800,
      total_units: 24,
      expected_completion_date: 24.months.from_now,
      reference_number: "RHA-2025-002",
      organization: organization,
      project_manager: manager_user
    )
  }
  
  let!(:commercial_project) {
    create(:immo_promo_project,
      name: "Centre Commercial Nova",
      description: "Centre commercial moderne avec 15 boutiques",
      project_type: "commercial",
      status: "planning", 
      total_budget_cents: 800000000,
      city: "Marseille",
      address: "78 Boulevard du Commerce",
      total_area: 3500,
      total_units: 15,
      expected_completion_date: 36.months.from_now,
      reference_number: "CCN-2025-003",
      organization: organization,
      project_manager: manager_user
    )
  }

  describe "Admin User Workflow" do
    before { login_as(admin_user, scope: :user) }
    
    it "can access all projects and perform all actions", js: true do
      visit "/immo/promo/projects"
      
      # Should see all projects
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("Résidence Harmony") 
      expect(page).to have_content("Centre Commercial Nova")
      
      # Should be able to access project details
      click_link "Villa Les Oliviers"
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("VLO-2025-001")
      expect(page).to have_content("1 800 000 €")
      
      # Should see management actions
      expect(page).to have_link("Modifier")
      expect(page).to have_link("Phases")
      expect(page).to have_link("Budget")
      expect(page).to have_link("Permis")
    end
    
    it "can create new projects", js: true do
      visit "/immo/promo/projects"
      
      click_link "Nouveau projet"
      
      fill_in "project_name", with: "Test Admin Project"
      fill_in "project_description", with: "Project created by admin"
      select "Résidentiel", from: "project_project_type"
      fill_in "project_city", with: "Nice"
      fill_in "project_total_budget_cents", with: "1000000"
      
      click_button "Créer le projet"
      
      expect(page).to have_content("Projet créé avec succès")
      expect(page).to have_content("Test Admin Project")
    end
  end

  describe "Manager User Workflow" do
    before { login_as(manager_user, scope: :user) }
    
    it "can access and manage assigned projects", js: true do
      visit "/immo/promo/projects"
      
      # Should see all projects since they're the project manager
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("Résidence Harmony")
      expect(page).to have_content("Centre Commercial Nova")
      
      # Should be able to access project details
      click_link "Villa Les Oliviers"
      expect(page).to have_content("Villa Les Oliviers")
      
      # Should see management actions for projects they manage
      expect(page).to have_link("Modifier")
      expect(page).to have_link("Budget")
      expect(page).to have_link("Permis")
    end
    
    it "can manage project budget", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      click_link "Budget"
      
      expect(page).to have_content("Budget du projet")
      expect(page).to have_content("1 800 000 €")
    end
    
    it "can create and manage permits", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      click_link "Permis"
      
      expect(page).to have_content("Permis et Autorisations")
      
      click_link "Nouveau permis"
      
      fill_in "permit_name", with: "Permis de construire villa"
      select "Permis de construire", from: "permit_permit_type"
      fill_in "permit_description", with: "Construction villa Les Oliviers"
      
      click_button "Créer le permis"
      
      expect(page).to have_content("Permis créé avec succès")
    end
  end

  describe "Controller User Workflow (Read-Only Access)" do
    before { login_as(controller_user, scope: :user) }
    
    it "can view projects but has limited access to details", js: true do
      visit "/immo/promo/projects"
      
      # Should see projects (due to immo_promo:access permission)
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("Résidence Harmony")
      expect(page).to have_content("Centre Commercial Nova")
      
      # Should be able to click on projects
      click_link "Villa Les Oliviers"
      
      # Should see basic project information
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("VLO-2025-001")
      
      # Should NOT see management actions
      expect(page).not_to have_link("Modifier")
      expect(page).not_to have_link("Supprimer")
    end
    
    it "cannot access budget management", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Should not see budget link or should be denied access
      if page.has_link?("Budget")
        click_link "Budget"
        expect(page).to have_content("non autorisé").or have_content("pas les droits")
      else
        expect(page).not_to have_link("Budget")
      end
    end
    
    it "cannot create new projects", js: true do
      visit "/immo/promo/projects"
      
      expect(page).not_to have_link("Nouveau projet")
    end
  end

  describe "Architect User Workflow" do
    before { login_as(architect_user, scope: :user) }
    
    it "can access projects and make modifications", js: true do
      visit "/immo/promo/projects"
      
      # Should see projects
      expect(page).to have_content("Villa Les Oliviers")
      
      click_link "Villa Les Oliviers"
      
      # Should be able to modify project (has immo_promo:projects:write)
      expect(page).to have_link("Modifier")
      
      click_link "Modifier"
      
      fill_in "project_description", with: "Updated by architect"
      click_button "Mettre à jour le projet"
      
      expect(page).to have_content("Projet modifié avec succès")
      expect(page).to have_content("Updated by architect")
    end
    
    it "can access phases but not budget", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Should see phases
      expect(page).to have_link("Phases")
      
      # Should not see budget management
      expect(page).not_to have_link("Budget")
    end
  end

  describe "Finance User Workflow" do
    before { login_as(finance_user, scope: :user) }
    
    it "can access financial data and budget management", js: true do
      visit "/immo/promo/projects"
      
      expect(page).to have_content("Villa Les Oliviers")
      
      click_link "Villa Les Oliviers"
      
      # Should see budget information (has immo_promo:financial:read)
      expect(page).to have_content("1 800 000 €")
      
      # Should be able to access budget management
      expect(page).to have_link("Budget")
      
      click_link "Budget"
      
      expect(page).to have_content("Budget du projet")
      expect(page).to have_content("1 800 000 €")
    end
    
    it "cannot modify project details", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Should not see project modification options
      expect(page).not_to have_link("Modifier")
    end
    
    it "can view financial summary across projects", js: true do
      visit "/immo/promo/projects"
      
      # Should see budget information in project cards
      expect(page).to have_content("1 800 000 €") # Villa
      expect(page).to have_content("4 500 000 €") # Residence  
      expect(page).to have_content("8 000 000 €") # Commercial
    end
  end

  describe "Cross-User Permission Scenarios" do
    it "project manager can delegate specific permissions", js: true do
      # Create an authorization for architect on specific project
      create(:authorization,
        authorizable: villa_project,
        user: architect_user,
        permission_level: 'write',
        granted_by: manager_user
      )
      
      login_as(architect_user, scope: :user)
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Should now have additional access to this specific project
      expect(page).to have_link("Modifier")
    end
    
    it "unauthorized user cannot access projects", js: true do
      unauthorized_user = create(:user, 
        email: "unauthorized@test.com",
        organization: organization,
        permissions: {}
      )
      
      login_as(unauthorized_user, scope: :user)
      visit "/immo/promo/projects"
      
      # Should not see any projects or be redirected
      expect(page).to have_content("non autorisé").or have_content("Aucun projet")
    end
  end

  describe "Navigation and Interface Tests" do
    before { login_as(manager_user, scope: :user) }
    
    it "shows proper navigation and project counts", js: true do
      visit "/immo/promo/projects"
      
      # Should show project count
      expect(page).to have_content("3 projets")
      
      # Should have navigation elements
      expect(page).to have_link("Tableau de bord")
      expect(page).to have_link("Projets")
      
      # Should show project status distribution
      expect(page).to have_content("Planification") # villa_project
      expect(page).to have_content("Construction") # residence_project  
      expect(page).to have_content("Planification") # commercial_project
    end
    
    it "allows filtering and sorting projects", js: true do
      visit "/immo/promo/projects"
      
      # Test status filter
      if page.has_select?("status")
        select "Construction", from: "status"
        expect(page).to have_content("Résidence Harmony")
        expect(page).not_to have_content("Villa Les Oliviers")
      end
      
      # Test project type filter  
      if page.has_select?("project_type")
        select "Commercial", from: "project_type"
        expect(page).to have_content("Centre Commercial Nova")
        expect(page).not_to have_content("Villa Les Oliviers")
      end
    end
  end
end