# Smoke test rapide pour vérifier les fonctionnalités critiques avant la démo
require 'rails_helper'

RSpec.describe "Demo Smoke Test", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:admin) do
    User.find_or_create_by(email: "admin@docusphere.fr") do |u|
      u.organization = organization
      u.password = "password123"
      u.role = "admin"
      u.first_name = "Admin"
      u.last_name = "Demo"
      u.confirmed_at = Time.current
    end
  end

  describe "Login and Navigation" do
    it "can login successfully" do
      visit root_path
      
      # Should redirect to login
      expect(page).to have_current_path(new_user_session_path)
      
      # Login
      fill_in "Adresse email", with: admin.email
      fill_in "Mot de passe", with: admin.password
      click_button "Se connecter"
      
      # Should be logged in
      expect(page).to have_content("Connexion réussie")
      expect(page).to have_current_path(root_path)
    end
  end

  describe "GED Basic Operations" do
    before do
      login_as(admin, scope: :user)
    end

    it "can access GED dashboard" do
      visit "/ged"
      
      expect(page).to have_content("Gestion Documentaire")
      expect(page).to have_link("Nouvel espace")
    end

    it "can create a space" do
      visit "/ged"
      click_link "Nouvel espace"
      
      within("#new-space-modal") do
        fill_in "space[name]", with: "Espace Test"
        fill_in "space[description]", with: "Description test"
        click_button "Créer l'espace"
      end
      
      expect(page).to have_content("Espace créé avec succès")
      expect(page).to have_content("Espace Test")
    end
  end

  describe "ImmoPromo Access" do
    before do
      login_as(admin, scope: :user)
    end

    it "can access ImmoPromo projects" do
      visit "/immo/promo/projects"
      
      expect(page).to have_content("Projets")
      expect(page).to have_link("Nouveau projet")
      expect(page).not_to have_content("Erreur")
    end

    it "can create a project" do
      visit "/immo/promo/projects/new"
      
      fill_in "immo_promo_project[name]", with: "Projet Démo"
      select "Résidentiel", from: "immo_promo_project[project_type]"
      fill_in "immo_promo_project[description]", with: "Projet de démonstration"
      fill_in "immo_promo_project[address]", with: "123 rue de la Démo"
      fill_in "immo_promo_project[city]", with: "Paris"
      fill_in "immo_promo_project[postal_code]", with: "75001"
      fill_in "immo_promo_project[total_units]", with: "50"
      
      click_button "Créer le projet"
      
      expect(page).to have_content("Projet créé avec succès")
      expect(page).to have_content("Projet Démo")
    end
  end

  describe "UI Components" do
    before do
      login_as(admin, scope: :user)
    end

    it "displays modern UI components" do
      visit "/ged"
      
      # Check for stat cards
      expect(page).to have_css(".stat-card", wait: 5)
      
      # Check for responsive navbar
      expect(page).to have_css("nav", wait: 5)
      
      # Check for user menu
      expect(page).to have_css(".user-avatar", wait: 5)
    end
  end

  describe "Document Upload" do
    let(:space) { create(:space, organization: organization) }
    
    before do
      login_as(admin, scope: :user)
    end

    it "can upload a document" do
      visit "/ged?space_id=#{space.id}"
      
      click_link "Ajouter un document"
      
      within("#upload-document-modal") do
        fill_in "document[title]", with: "Document Test"
        attach_file "document[file]", Rails.root.join("spec/fixtures/sample.pdf")
        click_button "Télécharger"
      end
      
      expect(page).to have_content("Document téléchargé avec succès")
      expect(page).to have_content("Document Test")
    end
  end
end