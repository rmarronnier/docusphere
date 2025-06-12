require 'rails_helper'

RSpec.describe 'Chef de Projet User Journey', type: :system do
  let(:organization) { create(:organization, name: 'Meridia Group') }
  let(:chef_projet) { create(:user, name: 'Julien Leroy', email: 'julien.leroy@meridia.fr', organization: organization) }
  let!(:project) { create(:project, name: 'Résidence Horizon', organization: organization, project_manager: chef_projet) }
  let!(:phase) { create(:phase, project: project, name: 'Terrassement', status: 'in_progress') }
  let!(:task) { create(:task, phase: phase, name: 'Excavation principale', assigned_to: chef_projet) }
  
  before do
    chef_projet.add_role(:chef_projet)
    sign_in chef_projet
  end
  
  describe 'Project Dashboard Access' do
    it 'views personalized project dashboard' do
      visit root_path
      
      expect(page).to have_content('Mes Projets')
      expect(page).to have_content('Résidence Horizon')
      
      within '.project-documents-widget' do
        expect(page).to have_content('Documents par phase')
        expect(page).to have_content('Terrassement')
        expect(page).to have_css('.phase-progress')
      end
      
      within '.pending-documents-widget' do
        expect(page).to have_content('Documents en attente')
        expect(page).to have_content('Brouillons')
        expect(page).to have_content('En validation')
      end
    end
  end
  
  describe 'Planning Management' do
    it 'manages project planning and tasks' do
      visit immo_promo_engine.planning_index_path
      
      expect(page).to have_content('Planning')
      expect(page).to have_content('Résidence Horizon')
      
      # View Gantt chart
      click_link 'Vue Gantt'
      expect(page).to have_css('.gantt-chart')
      expect(page).to have_content('Terrassement')
      expect(page).to have_content('Excavation principale')
      
      # Update task progress
      within "#task_#{task.id}" do
        find('.progress-slider').set(75)
        click_button 'Mettre à jour'
      end
      
      expect(page).to have_content('Progression mise à jour')
      expect(task.reload.progress).to eq(75)
      
      # Check critical path
      click_link 'Chemin critique'
      expect(page).to have_css('.critical-path-highlight')
      expect(page).to have_content('Tâches critiques')
    end
    
    it 'reschedules project timeline' do
      visit immo_promo_engine.planning_path(project)
      
      click_button 'Replanifier'
      
      within '.reschedule-modal' do
        fill_in 'Nouvelle date de début', with: 2.weeks.from_now.to_date
        fill_in 'Raison', with: 'Retard livraison matériaux'
        click_button 'Confirmer replanification'
      end
      
      expect(page).to have_content('Planning mis à jour avec succès')
      expect(page).to have_content('Notification envoyée aux parties prenantes')
    end
  end
  
  describe 'Resource Allocation' do
    it 'manages team resources and assignments' do
      visit immo_promo_engine.resources_path
      
      expect(page).to have_content('Gestion des Ressources')
      
      # View resource allocation matrix
      within '.allocation-matrix' do
        expect(page).to have_content('Taux d\'occupation')
        expect(page).to have_css('.resource-timeline')
      end
      
      # Assign resource to task
      click_link 'Nouvelle assignation'
      
      select 'François Moreau', from: 'Ressource'
      select 'Résidence Horizon', from: 'Projet'
      select 'Supervision chantier', from: 'Rôle'
      fill_in 'Allocation', with: '80'
      fill_in 'Date début', with: Date.current
      fill_in 'Date fin', with: 1.month.from_now
      
      click_button 'Assigner'
      
      expect(page).to have_content('Ressource assignée avec succès')
      expect(page).to have_content('François Moreau - 80%')
    end
    
    it 'detects and resolves resource conflicts' do
      visit immo_promo_engine.resources_allocation_path
      
      within '.conflicts-section' do
        expect(page).to have_content('Conflits détectés')
        
        first('.conflict-item').click
      end
      
      expect(page).to have_content('Résolution de conflit')
      expect(page).to have_content('Surallocation détectée')
      
      # Resolve conflict
      click_button 'Réaffecter'
      
      within '.reallocation-modal' do
        select 'Autre ressource disponible', from: 'Nouvelle ressource'
        click_button 'Confirmer réaffectation'
      end
      
      expect(page).to have_content('Conflit résolu')
    end
  end
  
  describe 'Document Management for Project' do
    it 'uploads and organizes project documents' do
      visit project_documents_path(project)
      
      expect(page).to have_content('Documents - Résidence Horizon')
      
      # Upload new document
      click_link 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/plan_masse.pdf')
        select 'Plans', from: 'Catégorie'
        select 'Terrassement', from: 'Phase'
        fill_in 'Description', with: 'Plan de masse actualisé'
        
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Document téléversé avec succès')
      expect(page).to have_content('plan_masse.pdf')
      
      # Organize in folders
      within '.document-item' do
        click_button 'Actions'
        click_link 'Déplacer'
      end
      
      select 'Plans techniques', from: 'Dossier cible'
      click_button 'Déplacer'
      
      expect(page).to have_content('Document déplacé')
    end
    
    it 'requests validation for critical documents' do
      document = create(:document, name: 'Devis terrassement', documentable: project)
      
      visit ged_document_path(document)
      
      click_link 'Demander validation'
      
      within '.validation-request-form' do
        select 'Marie Dubois', from: 'Validateur'
        select 'Haute', from: 'Priorité'
        fill_in 'Message', with: 'Validation urgente requise pour démarrer les travaux'
        fill_in 'Date limite', with: 3.days.from_now
        
        click_button 'Envoyer demande'
      end
      
      expect(page).to have_content('Demande de validation envoyée')
      expect(page).to have_content('En attente de validation')
    end
  end
  
  describe 'Progress Reporting' do
    it 'creates weekly progress report' do
      visit immo_promo_engine.project_path(project)
      
      click_link 'Nouveau rapport d\'avancement'
      
      within '.progress-report-form' do
        fill_in 'Période', with: 'Semaine 49 - 2025'
        fill_in 'Avancement global', with: '35'
        fill_in 'Points clés', with: '- Terrassement complété à 75%\n- Début des fondations semaine prochaine'
        fill_in 'Risques identifiés', with: 'Retard potentiel livraison béton'
        fill_in 'Actions requises', with: 'Confirmer planning avec fournisseur béton'
        
        # Attach photos
        attach_file 'Photos chantier', [
          Rails.root.join('spec/fixtures/files/chantier_1.jpg'),
          Rails.root.join('spec/fixtures/files/chantier_2.jpg')
        ]
        
        click_button 'Créer rapport'
      end
      
      expect(page).to have_content('Rapport créé avec succès')
      expect(page).to have_content('Semaine 49 - 2025')
      expect(page).to have_css('.progress-photos')
    end
  end
  
  describe 'Stakeholder Communication' do
    it 'manages stakeholder communications' do
      visit immo_promo_engine.project_stakeholders_path(project)
      
      expect(page).to have_content('Intervenants - Résidence Horizon')
      
      # Send update to stakeholders
      click_link 'Nouvelle communication'
      
      within '.communication-form' do
        check 'Tous les intervenants'
        select 'Mise à jour projet', from: 'Type'
        fill_in 'Objet', with: 'Point d\'avancement hebdomadaire'
        fill_in 'Message', with: 'Veuillez trouver ci-joint le rapport d\'avancement de la semaine.'
        
        attach_file 'Pièces jointes', Rails.root.join('spec/fixtures/files/rapport_s49.pdf')
        
        click_button 'Envoyer'
      end
      
      expect(page).to have_content('Communication envoyée à 12 intervenants')
      expect(page).to have_content('Historique des communications')
    end
  end
  
  describe 'Mobile Site Management' do
    it 'manages project from mobile on construction site', js: true do
      # Simulate mobile viewport
      page.driver.browser.manage.window.resize_to(375, 812)
      
      visit immo_promo_engine.project_path(project)
      
      # Quick actions should be prominent
      expect(page).to have_css('.mobile-quick-actions')
      
      # Take and upload site photo
      within '.mobile-quick-actions' do
        click_button 'Photo chantier'
      end
      
      within '.photo-upload-modal' do
        attach_file 'photo', Rails.root.join('spec/fixtures/files/site_photo.jpg')
        fill_in 'Commentaire', with: 'Avancement dalle béton'
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Photo ajoutée')
      
      # Quick task update
      find('.mobile-menu-toggle').click
      click_link 'Mes tâches'
      
      within '.task-list-mobile' do
        first('.task-item').click
        find('.quick-progress-update').click
        select '100%', from: 'progress'
        click_button 'OK'
      end
      
      expect(page).to have_content('Tâche mise à jour')
    end
  end
  
  describe 'Risk Management' do
    it 'identifies and manages project risks' do
      visit immo_promo_engine.project_risks_path(project)
      
      click_link 'Nouveau risque'
      
      within '.risk-form' do
        fill_in 'Titre', with: 'Retard approvisionnement acier'
        select 'Approvisionnement', from: 'Catégorie'
        select 'Élevée', from: 'Probabilité'
        select 'Majeur', from: 'Impact'
        fill_in 'Description', with: 'Pénurie mondiale d\'acier pourrait retarder la livraison'
        fill_in 'Mitigation', with: 'Commander avec 2 mois d\'avance, identifier fournisseurs alternatifs'
        
        click_button 'Créer risque'
      end
      
      expect(page).to have_content('Risque enregistré')
      expect(page).to have_css('.risk-matrix')
      expect(page).to have_content('Score: Élevé')
      
      # Create mitigation task
      within '.risk-item' do
        click_link 'Créer tâche de mitigation'
      end
      
      fill_in 'Tâche', with: 'Identifier 3 fournisseurs alternatifs'
      select 'François Moreau', from: 'Responsable'
      fill_in 'Date limite', with: 1.week.from_now
      
      click_button 'Créer tâche'
      
      expect(page).to have_content('Tâche de mitigation créée')
    end
  end
end