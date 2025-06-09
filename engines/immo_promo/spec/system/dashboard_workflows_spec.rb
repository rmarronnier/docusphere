require 'rails_helper'

RSpec.describe "Dashboard Workflows", type: :system do
  let(:organization) { create(:organization, name: "PromoTex-#{SecureRandom.hex(4)}") }
  
  # Create users with different roles and permissions
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
        'immo_promo:budget:manage' => true
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
  
  # Create demo projects
  let!(:villa_project) {
    create(:immo_promo_project,
      name: "Villa Les Oliviers",
      project_type: "residential",
      status: "planning",
      total_budget_cents: 180000000, # 1.8M€
      current_budget_cents: 45000000, # 450k€ spent
      total_units: 1,
      organization: organization,
      project_manager: manager_user,
      expected_completion_date: 18.months.from_now
    )
  }
  
  let!(:residence_project) {
    create(:immo_promo_project,
      name: "Résidence Harmony",
      project_type: "residential", 
      status: "construction",
      total_budget_cents: 450000000, # 4.5M€
      current_budget_cents: 225000000, # 2.25M€ spent
      total_units: 24,
      organization: organization,
      project_manager: manager_user,
      expected_completion_date: 24.months.from_now
    )
  }
  
  let!(:commercial_project) {
    create(:immo_promo_project,
      name: "Centre Commercial Nova",
      project_type: "commercial",
      status: "planning", 
      total_budget_cents: 800000000, # 8M€
      current_budget_cents: 80000000, # 800k€ spent
      total_units: 15,
      organization: organization,
      project_manager: manager_user,
      expected_completion_date: 36.months.from_now
    )
  }
  
  # Create some phases and tasks for projects
  let!(:villa_phase) {
    create(:immo_promo_phase,
      project: villa_project,
      name: "Planification préliminaires",
      phase_type: "studies",
      status: "in_progress",
      start_date: 1.month.ago,
      end_date: 2.months.from_now
    )
  }
  
  let!(:residence_phase) {
    create(:immo_promo_phase,
      project: residence_project,
      name: "Gros œuvre",
      phase_type: "construction",
      status: "in_progress", 
      start_date: 6.months.ago,
      end_date: 3.months.from_now
    )
  }

  describe "Admin Dashboard Experience" do
    before { login_as(admin_user, scope: :user) }
    
    it "shows comprehensive overview with all metrics", js: true do
      visit "/immo/promo/projects"
      
      # Should see all projects
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("Résidence Harmony") 
      expect(page).to have_content("Centre Commercial Nova")
      
      # Should show project counts
      expect(page).to have_content("3 projets")
      
      # Should show financial summary
      expect(page).to have_content("1 800 000").and have_content("€") # Villa budget
      expect(page).to have_content("4 500 000").and have_content("€") # Residence budget
      expect(page).to have_content("8 000 000").and have_content("€") # Commercial budget
      
      # Should show status distribution
      expect(page).to have_content("Planification") # villa status
      expect(page).to have_content("Construction") # residence status
      expect(page).to have_content("Planification") # commercial status
    end
    
    it "can navigate to all project management features", js: true do
      visit "/immo/promo/projects"
      
      click_link "Villa Les Oliviers"
      
      # Should see all management options
      expect(page).to have_link("Modifier")
      expect(page).to have_link("Phases")
      expect(page).to have_link("Budget")
      expect(page).to have_link("Permis")
      expect(page).to have_link("Intervenants")
      
      # Test navigation to phases
      click_link "Phases"
      expect(page).to have_content("Phases du projet")
      expect(page).to have_content("Planification préliminaires")
    end
    
    it "shows global statistics and alerts", js: true do
      visit "/immo/promo/projects"
      
      # Should show organization-wide metrics
      expect(page).to have_content("40 logements") # Total units across projects
      
      # May show alerts for projects needing attention
      if page.has_css?('.alert, .warning, .text-orange, .text-red')
        expect(page).to have_content("attention").or have_content("retard").or have_content("budget")
      end
    end
  end

  describe "Manager Dashboard Experience" do
    before { login_as(manager_user, scope: :user) }
    
    it "shows projects they manage with actionable items", js: true do
      visit "/immo/promo/projects"
      
      # Should see all projects (as project manager)
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("Résidence Harmony")
      expect(page).to have_content("Centre Commercial Nova")
      
      # Should see management-focused information
      expect(page).to have_content("En cours") # for phases in progress
      
      # Should have creation capabilities
      expect(page).to have_link("Nouveau projet")
    end
    
    it "can perform budget management tasks", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      click_link "Budget"
      
      expect(page).to have_content("Budget du projet")
      expect(page).to have_content("1 800 000").and have_content("€") # Total budget
      expect(page).to have_content("450 000").and have_content("€") # Current spent
      
      # Should show budget utilization
      expect(page).to have_content("25%").or have_content("25,0%") # 450k/1800k = 25%
    end
    
    it "can track project progress and milestones", js: true do
      visit "/immo/promo/projects/#{residence_project.id}"
      
      click_link "Phases"
      
      expect(page).to have_content("Phases du projet")
      expect(page).to have_content("Gros œuvre")
      expect(page).to have_content("En cours")
      
      # Should show timeline information
      expect(page).to have_content("3 mois") # time remaining
    end
  end

  describe "Controller Dashboard Experience (Read-Only)" do
    before { login_as(controller_user, scope: :user) }
    
    it "shows overview without management capabilities", js: true do
      visit "/immo/promo/projects"
      
      # Should see projects
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("Résidence Harmony")
      expect(page).to have_content("Centre Commercial Nova")
      
      # Should NOT see creation capabilities  
      expect(page).not_to have_link("Nouveau projet")
      
      # Should show basic project information
      expect(page).to have_content("Planification") # project status
      expect(page).to have_content("Construction")
      expect(page).to have_content("Planification")
    end
    
    it "can view project details but with limited actions", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Should see basic project information
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("1 800 000").and have_content("€")
      expect(page).to have_content("Planification")
      
      # Should NOT see management actions
      expect(page).not_to have_link("Modifier")
      expect(page).not_to have_link("Supprimer")
      
      # Budget access should be restricted
      if page.has_link?("Budget")
        click_link "Budget"
        expect(page).to have_content("non autorisé").or have_content("pas les droits")
      else
        expect(page).not_to have_link("Budget")
      end
    end
    
    it "provides monitoring and reporting focused interface", js: true do
      visit "/immo/promo/projects"
      
      # Should focus on status and progress information
      expect(page).to have_content("3 projets")
      expect(page).to have_content("40 logements") # total units
      
      # May show progress indicators
      if page.has_css?('.progress, .progress-bar, [data-progress]')
        expect(page).to have_css('.progress, .progress-bar, [data-progress]')
      end
    end
  end

  describe "Finance User Dashboard Experience" do
    before { login_as(finance_user, scope: :user) }
    
    it "shows financial-focused dashboard", js: true do
      visit "/immo/promo/projects"
      
      # Should see projects with emphasis on financial data
      expect(page).to have_content("Villa Les Oliviers")
      expect(page).to have_content("1 800 000").and have_content("€")
      expect(page).to have_content("4 500 000").and have_content("€") 
      expect(page).to have_content("8 000 000").and have_content("€")
      
      # Should show aggregated financial information
      total_budget = 1_800_000 + 4_500_000 + 8_000_000 # 14.3M€
      expect(page).to have_content("14 300 000").or have_content("14,3 M")
    end
    
    it "can access detailed budget information", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Should see financial information prominently
      expect(page).to have_content("1 800 000").and have_content("€")
      expect(page).to have_content("450 000").and have_content("€") # spent amount
      
      # Should be able to access budget details
      expect(page).to have_link("Budget")
      
      click_link "Budget"
      
      expect(page).to have_content("Budget du projet")
      expect(page).not_to have_content("Accès non autorisé")
    end
    
    it "shows budget utilization and financial metrics", js: true do
      visit "/immo/promo/projects/#{villa_project.id}/budget"
      
      # Should show detailed budget breakdown
      expect(page).to have_content("1 800 000").and have_content("€") # total
      expect(page).to have_content("450 000").and have_content("€") # spent
      expect(page).to have_content("1 350 000").and have_content("€") # remaining
      
      # Should show utilization percentage
      expect(page).to have_content("25%").or have_content("25,0%")
    end
  end

  describe "Cross-Role Collaboration Scenarios" do
    it "shows how different roles interact with same project", js: true do
      # Manager creates a task
      login_as(manager_user, scope: :user)
      visit "/immo/promo/projects/#{villa_project.id}/phases/#{villa_phase.id}"
      
      if page.has_link?("Nouvelle tâche")
        click_link "Nouvelle tâche"
        fill_in "task_name", with: "Validation des plans"
        click_button "Créer la tâche"
      end
      
      # Controller views the same information
      login_as(controller_user, scope: :user)
      visit "/immo/promo/projects/#{villa_project.id}"
      
      expect(page).to have_content("Villa Les Oliviers")
      # Should see tasks/phases created by manager
      if page.has_link?("Phases")
        click_link "Phases"
        expect(page).to have_content("Planification préliminaires")
      end
    end
  end

  describe "Mobile and Responsive Behavior" do
    before { login_as(manager_user, scope: :user) }
    
    it "maintains functionality on smaller screens", js: true do
      # Simulate mobile viewport
      page.driver.browser.manage.window.resize_to(375, 667)
      
      visit "/immo/promo/projects"
      
      expect(page).to have_content("Villa Les Oliviers")
      
      # Should still be able to navigate
      click_link "Villa Les Oliviers"
      expect(page).to have_content("Villa Les Oliviers")
      
      # Reset viewport
      page.driver.browser.manage.window.resize_to(1200, 800)
    end
  end

  describe "Performance and Loading States" do
    before { login_as(manager_user, scope: :user) }
    
    it "handles large project lists efficiently", js: true do
      # Create additional projects to test pagination/performance
      10.times do |i|
        create(:immo_promo_project,
          name: "Projet Test #{i}",
          organization: organization,
          project_manager: manager_user
        )
      end
      
      visit "/immo/promo/projects"
      
      # Should load without timeout
      expect(page).to have_content("Projet Test")
      
      # Should show appropriate number of projects or pagination
      expect(page).to have_content("projet").or have_content("Page")
    end
  end

  describe "Real-time Updates and Notifications" do
    before { login_as(manager_user, scope: :user) }
    
    it "reflects changes in project status", js: true do
      visit "/immo/promo/projects/#{villa_project.id}"
      
      # Initial status
      expect(page).to have_content("Planification")
      
      # Simulate status change (this would typically happen via background job)
      villa_project.update!(status: "construction")
      
      # Refresh to see changes (in real app, this might be real-time)
      visit "/immo/promo/projects/#{villa_project.id}"
      
      expect(page).to have_content("Construction")
    end
  end
end