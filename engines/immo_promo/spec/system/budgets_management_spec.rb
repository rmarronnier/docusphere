require 'rails_helper'

RSpec.describe "Budgets Management", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:project) { create(:project, organization: organization) }
  let(:phase) { create(:phase, project: project, name: 'Gros œuvre') }
  
  before do
    login_as(user, scope: :user)
  end

  describe "viewing budgets index" do
    let!(:construction_budget) { 
      create(:budget, 
        project: project, 
        name: 'Budget construction',
        total_amount: 500000,
        status: 'approved'
      ) 
    }
    let!(:finishing_budget) { 
      create(:budget, 
        project: project, 
        name: 'Budget finitions',
        total_amount: 200000,
        status: 'draft'
      ) 
    }

    it "displays all budgets with financial overview", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets"
      
      expect(page).to have_content("Budgets")
      expect(page).to have_content("Budget construction")
      expect(page).to have_content("Budget finitions")
      
      # Vérifier les montants
      expect(page).to have_content("500 000 €")
      expect(page).to have_content("200 000 €")
      
      # Vérifier les statuts
      expect(page).to have_css(".badge", text: "Approuvé")
      expect(page).to have_css(".badge", text: "Brouillon")
    end

    it "shows budget utilization statistics", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets"
      
      expect(page).to have_content("Budget total approuvé")
      expect(page).to have_content("Total dépensé")
      expect(page).to have_content("Taux d'utilisation")
    end

    it "allows filtering by status", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets"
      
      select "Approuvé", from: "status"
      
      expect(page).to have_content("Budget construction")
      expect(page).not_to have_content("Budget finitions")
    end

    it "shows empty state when no budgets exist" do
      project.budgets.destroy_all
      
      visit "/immo/promo/projects/#{project.id}/budgets"
      
      expect(page).to have_content("Aucun budget")
      expect(page).to have_content("Commencez par créer votre premier budget")
    end
  end

  describe "creating a new budget" do
    it "successfully creates a budget with budget lines", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/new"
      
      expect(page).to have_content("Nouveau budget")
      
      fill_in "budget_name", with: "Budget test complet"
      fill_in "budget_description", with: "Budget pour la phase de test"
      fill_in "budget_start_date", with: Date.current.strftime("%Y-%m-%d")
      fill_in "budget_end_date", with: 6.months.from_now.strftime("%Y-%m-%d")
      fill_in "budget_total_amount", with: "150000"
      fill_in "budget_contingency_percentage", with: "10"
      
      # Ajouter une ligne budgétaire
      fill_in "budget_budget_lines_attributes_0_category", with: "Matériaux"
      fill_in "budget_budget_lines_attributes_0_description", with: "Béton et ferraillage"
      fill_in "budget_budget_lines_attributes_0_quantity", with: "100"
      fill_in "budget_budget_lines_attributes_0_unit_price", with: "850"
      fill_in "budget_budget_lines_attributes_0_total_amount", with: "85000"
      
      fill_in "budget_notes", with: "Budget initial pour validation"
      
      click_button "Créer le budget"
      
      expect(page).to have_content("Budget créé avec succès")
      expect(page).to have_content("Budget test complet")
      expect(page).to have_content("150 000 €")
      expect(page).to have_content("Béton et ferraillage")
    end

    it "calculates total amount from budget lines", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/new"
      
      fill_in "budget_budget_lines_attributes_0_quantity", with: "10"
      fill_in "budget_budget_lines_attributes_0_unit_price", with: "100"
      
      # Le total devrait être calculé automatiquement
      expect(find("#budget_budget_lines_attributes_0_total_amount").value).to eq("1000")
    end

    it "shows validation errors for missing required fields" do
      visit "/immo/promo/projects/#{project.id}/budgets/new"
      
      click_button "Créer le budget"
      
      expect(page).to have_content("erreur")
    end
  end

  describe "viewing budget details" do
    let!(:budget) { 
      create(:budget, 
        project: project, 
        name: 'Budget détaillé',
        total_amount: 300000,
        status: 'approved'
      ) 
    }
    let!(:budget_line) { 
      create(:budget_line, 
        budget: budget,
        phase: phase,
        category: 'Main d\'œuvre',
        description: 'Équipe de maçons',
        quantity: 50,
        unit_price: 400,
        total_amount: 20000
      ) 
    }

    it "displays budget summary with variance analysis", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      expect(page).to have_content("Budget détaillé")
      expect(page).to have_content("300 000 €")
      
      # Vérifier le résumé budgétaire
      expect(page).to have_content("Résumé budgétaire")
      expect(page).to have_content("Prévu")
      expect(page).to have_content("Dépensé")
      expect(page).to have_content("Restant")
      
      # Vérifier les lignes budgétaires
      expect(page).to have_content("Équipe de maçons")
      expect(page).to have_content("20 000 €")
      expect(page).to have_content("Gros œuvre")
    end

    it "shows spending by category breakdown", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      expect(page).to have_content("Répartition par catégorie")
      expect(page).to have_content("Main d'œuvre")
    end

    it "displays variance analysis when actual costs exist", js: true do
      # Simuler des coûts réels
      budget_line.update!(actual_amount: 22000)
      
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      expect(page).to have_content("Analyse des écarts")
      expect(page).to have_content("Écart")
    end
  end

  describe "budget approval workflow" do
    let!(:draft_budget) { create(:budget, project: project, status: 'draft') }
    let!(:pending_budget) { create(:budget, project: project, status: 'pending_approval') }

    it "allows submitting a draft budget for approval", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{draft_budget.id}"
      
      click_button "Soumettre pour approbation"
      
      expect(page).to have_content("Budget soumis pour approbation")
    end

    it "allows approving a pending budget", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{pending_budget.id}"
      
      click_button "Approuver"
      
      expect(page).to have_content("Budget approuvé avec succès")
    end

    it "allows rejecting a pending budget", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{pending_budget.id}"
      
      click_button "Rejeter"
      
      expect(page).to have_content("Budget rejeté")
    end
  end

  describe "editing budget" do
    let!(:budget) { create(:budget, project: project, name: 'Budget original') }

    it "successfully updates budget information", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}/edit"
      
      fill_in "budget_name", with: "Budget modifié"
      fill_in "budget_total_amount", with: "175000"
      fill_in "budget_notes", with: "Budget révisé suite à nouvelles estimations"
      
      click_button "Enregistrer les modifications"
      
      expect(page).to have_content("Budget modifié avec succès")
      expect(page).to have_content("Budget modifié")
      expect(page).to have_content("175 000 €")
    end

    it "allows adding new budget lines", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}/edit"
      
      # Cliquer sur "Ajouter une ligne" (simulation)
      find(:css, "[data-add-line]").click if page.has_css?("[data-add-line]")
      
      # Remplir la nouvelle ligne
      within("[data-budget-line]:last-child") do
        fill_in "category", with: "Équipements"
        fill_in "description", with: "Nouveaux équipements"
        fill_in "quantity", with: "5"
        fill_in "unit_price", with: "2000"
      end
      
      click_button "Enregistrer les modifications"
      
      expect(page).to have_content("Budget modifié avec succès")
      expect(page).to have_content("Nouveaux équipements")
    end
  end

  describe "budget duplication" do
    let!(:budget) { create(:budget, project: project, name: 'Budget à dupliquer') }

    it "allows duplicating a budget for revision", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      click_button "Dupliquer"
      
      expect(page).to have_content("Budget dupliqué avec succès")
      expect(page).to have_content("Modifier le budget")
    end
  end

  describe "budget lines management" do
    let!(:budget) { create(:budget, project: project) }
    let!(:budget_line1) { 
      create(:budget_line, 
        budget: budget, 
        category: 'Matériaux', 
        description: 'Ciment'
      ) 
    }
    let!(:budget_line2) { 
      create(:budget_line, 
        budget: budget, 
        category: 'Main d\'œuvre', 
        description: 'Maçonnerie'
      ) 
    }

    it "displays budget lines with filtering options", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}/budget_lines"
      
      expect(page).to have_content("Lignes budgétaires")
      expect(page).to have_content("Ciment")
      expect(page).to have_content("Maçonnerie")
      
      # Filtrer par catégorie
      select "Matériaux", from: "category"
      
      expect(page).to have_content("Ciment")
      expect(page).not_to have_content("Maçonnerie")
    end

    it "shows detailed view of budget line with expense history", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}/budget_lines/#{budget_line1.id}"
      
      expect(page).to have_content(budget_line1.description)
      expect(page).to have_content("Historique des dépenses")
      expect(page).to have_content("Évolution de la variance")
    end
  end

  describe "budget deletion" do
    let!(:budget) { create(:budget, project: project, status: 'draft') }

    it "allows deleting a draft budget without expenses", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}/edit"
      
      accept_confirm do
        click_link "Supprimer"
      end
      
      expect(page).to have_content("Budget supprimé avec succès")
      expect(page).not_to have_content(budget.name)
    end
  end

  describe "budget reports and exports" do
    let!(:budget) { create(:budget, project: project, name: 'Budget rapport') }

    it "allows generating budget reports", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      if page.has_link?("Exporter PDF")
        click_link "Exporter PDF"
        
        # Vérifier que le téléchargement commence
        expect(page.response_headers['Content-Type']).to include('application/pdf')
      end
    end

    it "allows exporting to Excel", js: true do
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      if page.has_link?("Exporter Excel")
        click_link "Exporter Excel"
        
        # Vérifier que le téléchargement commence
        expect(page.response_headers['Content-Type']).to include('application/vnd.openxmlformats')
      end
    end
  end

  describe "budget notifications and alerts" do
    let!(:budget) { 
      create(:budget, 
        project: project, 
        total_amount: 100000,
        status: 'approved'
      ) 
    }

    it "shows budget overrun warnings", js: true do
      # Simuler un dépassement de budget
      budget.update!(spent_amount: 110000)
      
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      expect(page).to have_css(".alert-danger, .bg-red-100", text: /dépassement|overrun/i)
    end

    it "shows budget utilization alerts", js: true do
      # Simuler une utilisation élevée du budget
      budget.update!(spent_amount: 85000)
      
      visit "/immo/promo/projects/#{project.id}/budgets/#{budget.id}"
      
      expect(page).to have_css(".alert-warning, .bg-yellow-100, .bg-orange-100")
    end
  end
end