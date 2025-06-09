require 'rails_helper'

RSpec.describe "Demo Critical Paths", type: :system do
  let(:organization) { create(:organization, name: "Demo Org") }
  let(:admin) { create(:user, :admin, organization: organization, email: "admin@demo.fr", password: "password123") }
  
  before do
    # Login once
    visit new_user_session_path
    fill_in "Adresse email", with: admin.email
    fill_in "Mot de passe", with: "password123"
    click_button "Se connecter"
  end

  describe "Core GED Features" do
    it "can create space and navigate" do
      visit ged_path
      
      # Create space
      click_link "Nouvel espace"
      fill_in "Nom", with: "Espace Demo"
      fill_in "Description", with: "Pour la démonstration"
      click_button "Créer"
      
      expect(page).to have_content("Espace créé avec succès")
      expect(page).to have_content("Espace Demo")
    end

    it "can upload a document" do
      space = create(:space, organization: organization)
      folder = create(:folder, space: space)
      
      visit ged_path(space_id: space.id, folder_id: folder.id)
      
      # Upload document
      click_link "Ajouter un document"
      fill_in "Titre", with: "Document Test"
      attach_file "document[file]", Rails.root.join("spec/fixtures/sample.pdf")
      click_button "Télécharger"
      
      expect(page).to have_content("Document téléchargé avec succès")
      expect(page).to have_content("Document Test")
    end
  end

  describe "ImmoPromo Features" do
    it "can access projects list" do
      visit immo_promo_engine.projects_path
      
      expect(page).to have_content("Projets")
      expect(page).to have_link("Nouveau projet")
    end

    it "can create a new project" do
      visit immo_promo_engine.projects_path
      click_link "Nouveau projet"
      
      fill_in "Nom", with: "Projet Demo"
      select "Résidentiel", from: "Type de projet"
      fill_in "Description", with: "Projet de démonstration"
      fill_in "Adresse", with: "123 rue de la Demo"
      fill_in "Ville", with: "Paris"
      fill_in "Code postal", with: "75001"
      
      click_button "Créer le projet"
      
      expect(page).to have_content("Projet créé avec succès")
      expect(page).to have_content("Projet Demo")
    end

    it "can view project details and phases" do
      project = create(:immo_promo_project, organization: organization, project_manager: admin)
      create(:immo_promo_phase, project: project, name: "Études", status: "in_progress")
      
      visit immo_promo_engine.project_path(project)
      
      expect(page).to have_content(project.name)
      expect(page).to have_content("Études")
      expect(page).to have_content("En cours")
    end
  end

  describe "Document Integration" do
    it "can access documents from project" do
      project = create(:immo_promo_project, organization: organization, project_manager: admin)
      
      visit immo_promo_engine.project_path(project)
      click_link "Documents"
      
      expect(page).to have_content("Documents du projet")
      expect(page).to have_link("Ajouter des documents")
    end
  end

  describe "UI Components" do
    it "displays dashboard with statistics" do
      create_list(:document, 5, space: create(:space, organization: organization))
      
      visit ged_path
      
      # Check for stat cards
      expect(page).to have_css(".stat-card")
      expect(page).to have_content("Documents")
      expect(page).to have_content("Espaces")
    end

    it "shows responsive navigation" do
      visit root_path
      
      # Desktop navigation
      expect(page).to have_css(".navbar")
      expect(page).to have_link("GED")
      expect(page).to have_link("ImmoPromo")
      
      # User menu
      expect(page).to have_css(".user-avatar")
    end
  end

  describe "Error Handling" do
    it "handles 404 gracefully" do
      visit "/nonexistent-page"
      
      expect(page).to have_content("404")
      expect(page).to have_link("Retour à l'accueil")
    end
  end
end