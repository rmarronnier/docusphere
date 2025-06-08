require 'rails_helper'

RSpec.describe "Stakeholders Management", type: :system do
  let(:user) { create(:user, :admin) }
  let(:organization) { user.organization }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  before do
    login_as(user, scope: :user)
  end

  describe "viewing stakeholders index" do
    let!(:architect) { create(:immo_promo_stakeholder, :architect, project: project, name: 'Jean Dupont') }
    let!(:engineer) { create(:immo_promo_stakeholder, project: project, stakeholder_type: 'engineer', name: 'Marie Martin') }

    it "displays all stakeholders with proper information", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders"
      
      expect(page).to have_content("Intervenants")
      expect(page).to have_content("2 intervenants")
      
      # Vérifier que les intervenants sont affichés
      expect(page).to have_content("Jean Dupont")
      expect(page).to have_content("Marie Martin")
      expect(page).to have_content("Architecte")
      expect(page).to have_content("Ingénieur")
    end

    it "allows filtering by role", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders"
      
      select "Architecte", from: "role"
      
      expect(page).to have_content("Jean Dupont")
      expect(page).not_to have_content("Marie Martin")
    end

    it "shows empty state when no stakeholders exist" do
      project.stakeholders.destroy_all
      
      visit "/immo/promo/projects/#{project.id}/stakeholders"
      
      expect(page).to have_content("Aucun intervenant")
      expect(page).to have_content("Commencez par ajouter vos premiers intervenants")
    end
  end

  describe "creating a new stakeholder" do
    it "successfully creates a stakeholder with all required information", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/new"
      
      expect(page).to have_content("Nouvel intervenant")
      
      fill_in "stakeholder_name", with: "Pierre Architecte"
      fill_in "stakeholder_email", with: "pierre@example.com"
      fill_in "stakeholder_phone", with: "0123456789"
      select "Architecte", from: "stakeholder_role"
      fill_in "stakeholder_company_name", with: "Architecture SARL"
      fill_in "stakeholder_siret", with: "12345678901234"
      select "Niveau 3", from: "stakeholder_qualification_level"
      fill_in "stakeholder_hourly_rate", with: "85"
      fill_in "stakeholder_daily_rate", with: "650"
      fill_in "stakeholder_address", with: "123 Rue de la Paix, 75001 Paris"
      fill_in "stakeholder_notes", with: "Architecte expérimenté en construction durable"
      
      click_button "Ajouter l'intervenant"
      
      expect(page).to have_content("Intervenant ajouté avec succès")
      expect(page).to have_content("Pierre Architecte")
      expect(page).to have_content("pierre@example.com")
      expect(page).to have_content("Architecture SARL")
    end

    it "shows validation errors for missing required fields" do
      visit "/immo/promo/projects/#{project.id}/stakeholders/new"
      
      click_button "Ajouter l'intervenant"
      
      expect(page).to have_content("erreur")
      expect(page).to have_content("empêche l'enregistrement")
    end
  end

  describe "viewing stakeholder details" do
    let!(:stakeholder) { create(:stakeholder, project: project, name: 'Expert BTP') }
    let!(:certification) { create(:certification, stakeholder: stakeholder, name: 'RGE') }
    let!(:contract) { create(:contract, stakeholder: stakeholder, project: project, amount: 50000) }

    it "displays stakeholder profile with all information", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}"
      
      expect(page).to have_content("Expert BTP")
      expect(page).to have_content(stakeholder.email)
      
      # Vérifier les onglets
      expect(page).to have_content("Certifications (1)")
      expect(page).to have_content("Contrats (1)")
      expect(page).to have_content("Activité récente")
    end

    it "allows navigation between tabs", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}"
      
      # Cliquer sur l'onglet Contrats
      click_button "Contrats (1)"
      
      expect(page).to have_content("50 000 €")
      
      # Cliquer sur l'onglet Certifications
      click_button "Certifications (1)"
      
      expect(page).to have_content("RGE")
    end
  end

  describe "editing stakeholder" do
    let!(:stakeholder) { create(:stakeholder, project: project, name: 'Original Name') }

    it "successfully updates stakeholder information", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}/edit"
      
      fill_in "stakeholder_name", with: "Updated Name"
      fill_in "stakeholder_notes", with: "Notes mises à jour"
      
      click_button "Enregistrer les modifications"
      
      expect(page).to have_content("Intervenant modifié avec succès")
      expect(page).to have_content("Updated Name")
    end
  end

  describe "stakeholder approval workflow" do
    let!(:pending_stakeholder) { create(:stakeholder, project: project, status: 'pending') }

    it "allows approving a pending stakeholder", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/#{pending_stakeholder.id}"
      
      expect(page).to have_button("Approuver")
      expect(page).to have_button("Rejeter")
      
      click_button "Approuver"
      
      expect(page).to have_content("Intervenant approuvé avec succès")
    end

    it "allows rejecting a pending stakeholder", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/#{pending_stakeholder.id}"
      
      click_button "Rejeter"
      
      expect(page).to have_content("Intervenant rejeté")
    end
  end

  describe "stakeholder deletion" do
    let!(:stakeholder) { create(:stakeholder, project: project) }

    it "allows deleting a stakeholder without dependencies", js: true do
      visit "/immo/promo/projects/#{project.id}/stakeholders/#{stakeholder.id}/edit"
      
      accept_confirm do
        click_link "Supprimer"
      end
      
      expect(page).to have_content("Intervenant supprimé avec succès")
      expect(page).not_to have_content(stakeholder.name)
    end
  end
end