require 'rails_helper'

RSpec.describe "Permits Management", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:project) { create(:project, organization: organization) }
  
  before do
    login_as(user, scope: :user)
  end

  describe "viewing permits index" do
    let!(:building_permit) { 
      create(:permit, 
        project: project, 
        name: 'Permis de construire résidence',
        permit_type: 'building_permit',
        status: 'approved'
      ) 
    }
    let!(:work_permit) { 
      create(:permit, 
        project: project, 
        name: 'Autorisation travaux voirie',
        permit_type: 'work_authorization',
        status: 'submitted'
      ) 
    }

    it "displays all permits with proper information", js: true do
      visit "/immo/promo/projects/#{project.id}/permits"
      
      expect(page).to have_content("Permis et Autorisations")
      expect(page).to have_content("2 permis")
      
      # Vérifier que les permis sont affichés
      expect(page).to have_content("Permis de construire résidence")
      expect(page).to have_content("Autorisation travaux voirie")
      expect(page).to have_content("Permis de construire")
      expect(page).to have_content("Autorisation de travaux")
    end

    it "shows statistics in sidebar", js: true do
      visit "/immo/promo/projects/#{project.id}/permits"
      
      within('.bg-white.rounded-lg.shadow') do
        expect(page).to have_content("Total")
        expect(page).to have_content("2")
        expect(page).to have_content("Approuvés")
        expect(page).to have_content("1")
      end
    end

    it "allows filtering by status", js: true do
      visit "/immo/promo/projects/#{project.id}/permits"
      
      select "Approuvé", from: "status"
      
      expect(page).to have_content("Permis de construire résidence")
      expect(page).not_to have_content("Autorisation travaux voirie")
    end

    it "allows filtering by type", js: true do
      visit "/immo/promo/projects/#{project.id}/permits"
      
      select "Permis de construire", from: "permit_type"
      
      expect(page).to have_content("Permis de construire résidence")
      expect(page).not_to have_content("Autorisation travaux voirie")
    end

    it "shows empty state when no permits exist" do
      project.permits.destroy_all
      
      visit "/immo/promo/projects/#{project.id}/permits"
      
      expect(page).to have_content("Aucun permis")
      expect(page).to have_content("Commencez par ajouter vos premiers permis")
    end
  end

  describe "creating a new permit" do
    it "successfully creates a permit with conditions", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/new"
      
      expect(page).to have_content("Nouveau permis")
      
      fill_in "permit_name", with: "Permis de construire villa"
      select "Permis de construire", from: "permit_type"
      fill_in "permit_description", with: "Construction d'une villa individuelle"
      fill_in "permit_issuing_authority", with: "Mairie de Lyon"
      fill_in "permit_reference_number", with: "PC69001234567"
      fill_in "permit_submission_date", with: Date.current.strftime("%Y-%m-%d")
      fill_in "permit_expected_approval_date", with: 3.months.from_now.strftime("%Y-%m-%d")
      fill_in "permit_cost", with: "1500"
      
      # Ajouter une condition
      fill_in "permit_conditions_attributes_0_description", with: "Raccordement électrique"
      fill_in "permit_conditions_attributes_0_deadline", with: 2.months.from_now.strftime("%Y-%m-%d")
      fill_in "permit_conditions_attributes_0_responsible_authority", with: "ENEDIS"
      
      fill_in "permit_notes", with: "Dossier complet déposé en mairie"
      
      click_button "Créer le permis"
      
      expect(page).to have_content("Permis créé avec succès")
      expect(page).to have_content("Permis de construire villa")
      expect(page).to have_content("PC69001234567")
      expect(page).to have_content("Raccordement électrique")
    end

    it "shows validation errors for missing required fields" do
      visit "/immo/promo/projects/#{project.id}/permits/new"
      
      click_button "Créer le permis"
      
      expect(page).to have_content("erreur")
    end
  end

  describe "viewing permit details" do
    let!(:permit) { 
      create(:permit, 
        project: project, 
        name: 'Permis test',
        permit_type: 'building_permit',
        status: 'approved',
        reference_number: 'PC123456',
        cost: 2000
      ) 
    }
    let!(:condition) { 
      create(:permit_condition, 
        permit: permit, 
        description: 'Étude géotechnique',
        deadline: 1.month.from_now,
        status: 'pending'
      ) 
    }

    it "displays permit details with conditions and timeline", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{permit.id}"
      
      expect(page).to have_content("Permis test")
      expect(page).to have_content("PC123456")
      expect(page).to have_content("2 000 €")
      
      # Vérifier les conditions
      expect(page).to have_content("Conditions (1)")
      expect(page).to have_content("Étude géotechnique")
      
      # Vérifier la timeline
      expect(page).to have_content("Chronologie")
    end

    it "shows permit actions based on status", js: true do
      permit.update!(status: 'submitted')
      
      visit "/immo/promo/projects/#{project.id}/permits/#{permit.id}"
      
      expect(page).to have_button("Approuver")
      expect(page).to have_button("Rejeter")
    end
  end

  describe "permit workflow" do
    let!(:draft_permit) { create(:permit, project: project, status: 'draft') }
    let!(:submitted_permit) { create(:permit, project: project, status: 'submitted') }

    it "allows submitting a draft permit for approval", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{draft_permit.id}"
      
      click_button "Soumettre pour approbation"
      
      expect(page).to have_content("Permis soumis pour approbation")
    end

    it "allows approving a submitted permit", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{submitted_permit.id}"
      
      click_button "Approuver"
      
      expect(page).to have_content("Permis approuvé avec succès")
    end

    it "allows rejecting a submitted permit", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{submitted_permit.id}"
      
      click_button "Rejeter"
      
      expect(page).to have_content("Permis rejeté")
    end
  end

  describe "editing permit" do
    let!(:permit) { create(:permit, project: project, name: 'Original Permit') }

    it "successfully updates permit information", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{permit.id}/edit"
      
      fill_in "permit_name", with: "Updated Permit Name"
      fill_in "permit_notes", with: "Notes mises à jour"
      
      click_button "Enregistrer les modifications"
      
      expect(page).to have_content("Permis modifié avec succès")
      expect(page).to have_content("Updated Permit Name")
    end
  end

  describe "permit conditions management" do
    let!(:permit) { create(:permit, project: project) }
    let!(:condition) { 
      create(:permit_condition, 
        permit: permit, 
        description: 'Condition test',
        status: 'pending'
      ) 
    }

    it "shows conditions with proper status indicators", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{permit.id}"
      
      expect(page).to have_content("Condition test")
      expect(page).to have_css(".badge", text: "En attente")
    end

    it "allows marking conditions as completed", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{permit.id}/edit"
      
      select "Remplie", from: "permit_conditions_attributes_0_status"
      
      click_button "Enregistrer les modifications"
      
      expect(page).to have_content("Permis modifié avec succès")
    end
  end

  describe "permit deletion" do
    let!(:permit) { create(:permit, project: project, status: 'draft') }

    it "allows deleting a draft permit", js: true do
      visit "/immo/promo/projects/#{project.id}/permits/#{permit.id}/edit"
      
      accept_confirm do
        click_link "Supprimer"
      end
      
      expect(page).to have_content("Permis supprimé avec succès")
      expect(page).not_to have_content(permit.name)
    end
  end

  describe "expiry warnings" do
    let!(:expiring_permit) { 
      create(:permit, 
        project: project, 
        name: 'Permis expirant',
        expiry_date: 15.days.from_now,
        status: 'approved'
      ) 
    }

    it "shows expiry warnings for permits expiring soon", js: true do
      visit "/immo/promo/projects/#{project.id}/permits"
      
      expect(page).to have_content("Expire le")
      expect(page).to have_css(".text-orange-600")
    end
  end
end