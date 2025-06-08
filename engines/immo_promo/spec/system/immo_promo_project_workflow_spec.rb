require 'rails_helper'

RSpec.describe "Immo::Promo Project Workflow", type: :system do
  let(:admin) { create(:user, :admin) }
  
  before do
    # Donner les permissions Immo::Promo
    admin.add_permission!('immo_promo:access')
    login_as(admin, scope: :user)
  end
  
  describe "complete project creation and management workflow", js: true do
    it "creates a project, adds phases, assigns tasks, and tracks progress" do
      # 1. Aller sur la page des projets
      visit immo_promo_projects_path
      expect(page).to have_content("Projets immobiliers")
      
      # 2. Ouvrir la modale de création
      click_button "Nouveau projet"
      
      # Attendre que la modale s'ouvre
      expect(page).to have_css('[data-immo-promo-navbar-target="newProjectModal"]:not(.hidden)', wait: 2)
      
      # 3. Remplir le formulaire de création
      within '[data-immo-promo-navbar-target="newProjectModal"]' do
        fill_in "Nom du projet", with: "Résidence Les Jardins"
        fill_in "Référence", with: "RJ-2024-001"
        select "Résidentiel", from: "Type de projet"
        fill_in "Date de début", with: Date.today.strftime("%Y-%m-%d")
        fill_in "Date de fin prévisionnelle", with: 2.years.from_now.strftime("%Y-%m-%d")
        fill_in "Description", with: "Construction de 50 logements avec jardins privatifs"
        
        click_button "Créer le projet"
      end
      
      # 4. Vérifier la redirection vers le projet créé
      expect(page).to have_current_path(/\/immo_promo\/projects\/\d+/)
      expect(page).to have_content("Projet créé avec succès")
      expect(page).to have_content("Résidence Les Jardins")
      expect(page).to have_content("RJ-2024-001")
      
      # 5. Vérifier que les phases par défaut ont été créées
      within '.phases-section' do
        expect(page).to have_content("Études préliminaires")
        expect(page).to have_content("Obtention des permis")
        expect(page).to have_content("Travaux de construction")
        expect(page).to have_content("Réception des travaux")
        expect(page).to have_content("Livraison")
      end
      
      # 6. Ajouter une tâche à une phase
      within first('.phase-card') do
        click_button "Ajouter une tâche"
      end
      
      # Remplir le formulaire de tâche dans la modale
      within '#new-task-modal' do
        fill_in "Nom de la tâche", with: "Étude de sol"
        fill_in "Description", with: "Réaliser l'étude géotechnique du terrain"
        select admin.full_name, from: "Assigné à"
        fill_in "Date d'échéance", with: 1.month.from_now.strftime("%Y-%m-%d")
        select "Haute", from: "Priorité"
        
        click_button "Créer la tâche"
      end
      
      expect(page).to have_content("Tâche créée avec succès")
      expect(page).to have_content("Étude de sol")
      
      # 7. Marquer la tâche comme terminée
      within '.task-list' do
        task_row = find('.task-row', text: "Étude de sol")
        within task_row do
          click_button "Marquer comme terminée"
        end
      end
      
      expect(page).to have_css('.task-completed')
      expect(page).to have_content("Tâche mise à jour")
      
      # 8. Vérifier la mise à jour du pourcentage de progression
      within '.project-progress' do
        expect(page).to have_content(/\d+%/)
        progress_bar = find('.progress-bar')
        expect(progress_bar[:style]).to include('width:')
      end
      
      # 9. Ajouter un intervenant
      click_link "Intervenants"
      expect(page).to have_current_path(/\/stakeholders/)
      
      click_button "Ajouter un intervenant"
      
      within '#new-stakeholder-modal' do
        select "Architecte", from: "Type d'intervenant"
        fill_in "Nom de l'entreprise", with: "Cabinet Architecture Plus"
        fill_in "Nom du contact", with: "Jean Architecte"
        fill_in "Email", with: "contact@archiplus.fr"
        fill_in "Téléphone", with: "01 23 45 67 89"
        
        click_button "Ajouter"
      end
      
      expect(page).to have_content("Intervenant ajouté avec succès")
      expect(page).to have_content("Cabinet Architecture Plus")
      
      # 10. Créer un jalon (milestone)
      visit immo_promo_project_path(Immo::Promo::Project.last)
      
      within '.milestones-section' do
        click_button "Ajouter un jalon"
      end
      
      within '#new-milestone-modal' do
        fill_in "Nom du jalon", with: "Dépôt du permis de construire"
        fill_in "Date prévue", with: 3.months.from_now.strftime("%Y-%m-%d")
        fill_in "Description", with: "Dépôt du dossier complet en mairie"
        
        click_button "Créer"
      end
      
      expect(page).to have_content("Jalon créé avec succès")
      expect(page).to have_content("Dépôt du permis de construire")
      
      # 11. Tester le dashboard global
      visit immo_promo_dashboard_path
      
      expect(page).to have_content("Tableau de bord Immo::Promo")
      expect(page).to have_content("Résidence Les Jardins")
      
      # Vérifier les statistiques
      within '.dashboard-stats' do
        expect(page).to have_content("1", text: "Projets actifs")
        expect(page).to have_content("1", text: "Tâches en cours")
      end
      
      # 12. Vérifier les alertes
      within '.alerts-section' do
        # Si des tâches sont en retard ou des jalons approchent
        # expect(page).to have_content("Attention requise")
      end
      
      # 13. Test de la recherche de projet
      within '.projects-search' do
        fill_in "Rechercher", with: "Jardins"
        click_button "Rechercher"
      end
      
      expect(page).to have_content("Résidence Les Jardins")
      
      # 14. Export des données (si disponible)
      click_button "Exporter"
      select "PDF", from: "Format"
      click_button "Télécharger"
      
      # Vérifier que le téléchargement a commencé
      expect(page).to have_content("Export en cours")
    end
  end
  
  describe "error handling", js: true do
    it "shows validation errors when creating invalid project" do
      visit immo_promo_projects_path
      click_button "Nouveau projet"
      
      within '[data-immo-promo-navbar-target="newProjectModal"]' do
        # Soumettre sans remplir les champs obligatoires
        click_button "Créer le projet"
      end
      
      # Vérifier les messages d'erreur
      expect(page).to have_content("Le nom doit être rempli")
      expect(page).to have_content("La référence doit être remplie")
      
      # La modale doit rester ouverte
      expect(page).to have_css('[data-immo-promo-navbar-target="newProjectModal"]:not(.hidden)')
    end
  end
  
  describe "responsive behavior", js: true do
    it "works on mobile devices" do
      use_mobile_viewport
      
      visit immo_promo_projects_path
      
      # Le menu hamburger doit être visible
      expect(page).to have_css('.mobile-menu-toggle')
      
      # Ouvrir le menu mobile
      find('.mobile-menu-toggle').click
      
      expect(page).to have_css('.mobile-menu.open')
      
      # Naviguer vers un projet
      within '.mobile-menu' do
        click_link "Projets"
      end
      
      # Les cartes doivent être empilées verticalement
      expect(page).to have_css('.project-card')
      cards = all('.project-card')
      expect(cards.first.location.y).to be < cards.last.location.y
    end
  end
end