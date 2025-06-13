require 'rails_helper'

RSpec.describe 'Direction User Journey', type: :system do
  let(:organization) { create(:organization, name: 'Meridia Group') }
  let(:direction_user) { create(:user, first_name: 'Marie', last_name: 'Dubois', email: 'marie.dubois@meridia.fr', organization: organization) }
  let!(:project) { create(:immo_promo_project, name: 'Jardins de Belleville', organization: organization) }
  let!(:pending_validation) { create(:validation_request, validatable: create(:document, title: 'Permis de construire', space: create(:space, organization: organization))) }
  
  before do
    direction_user.update!(role: :admin) # Direction user needs admin role
    sign_in direction_user
  end
  
  describe 'Dashboard and Overview' do
    it 'accesses personalized dashboard with key metrics' do
      visit root_path
      
      # Should see direction-specific widgets
      expect(page).to have_content('Tableau de bord Direction')
      expect(page).to have_content('Validations en attente')
      expect(page).to have_content('Alertes de conformité')
      expect(page).to have_content('Rapports d\'activité')
      
      # Check metrics
      within '.validation-queue-widget' do
        expect(page).to have_content('Documents à valider')
        expect(page).to have_css('.priority-high')
      end
      
      within '.compliance-alerts-widget' do
        expect(page).to have_content('Échéances réglementaires')
      end
    end
  end
  
  describe 'Document Validation Workflow' do
    it 'reviews and approves critical documents' do
      visit root_path
      
      # Click on validation queue
      within '.validation-queue-widget' do
        click_link 'Voir toutes les validations'
      end
      
      expect(current_path).to eq(ged_my_validation_requests_path)
      
      # Select a document to validate
      within "#validation_#{pending_validation.id}" do
        expect(page).to have_content('Permis de construire')
        click_link 'Examiner'
      end
      
      # Review document details
      expect(page).to have_content('Demande de validation')
      expect(page).to have_content('Permis de construire')
      
      # Open document preview
      click_button 'Prévisualiser le document'
      
      # Wait for modal to open
      expect(page).to have_css('.document-preview-modal', visible: true)
      
      # Close preview
      find('.modal-close').click
      
      # Add validation comment and approve
      fill_in 'Commentaire', with: 'Document conforme aux exigences réglementaires. Approuvé pour soumission.'
      click_button 'Approuver'
      
      expect(page).to have_content('Document approuvé avec succès')
      expect(pending_validation.reload.status).to eq('approved')
    end
    
    it 'rejects document with feedback' do
      visit ged_document_validation_path(pending_validation.document, pending_validation)
      
      fill_in 'Commentaire', with: 'Informations manquantes sur la superficie totale. Merci de compléter.'
      click_button 'Rejeter'
      
      expect(page).to have_content('Document rejeté')
      expect(page).to have_content('Une notification a été envoyée au demandeur')
    end
  end
  
  describe 'Reports Generation and Analysis' do
    it 'generates activity report for board meeting' do
      visit reports_path
      
      expect(page).to have_content('Rapports')
      
      # Create new report
      click_link 'Nouveau rapport'
      
      select 'Rapport d\'activité', from: 'Type de rapport'
      fill_in 'Nom du rapport', with: 'Rapport Mensuel - Décembre 2025'
      fill_in 'Date de début', with: 1.month.ago.to_date
      fill_in 'Date de fin', with: Date.current
      
      check 'Inclure les graphiques'
      
      click_button 'Générer le rapport'
      
      expect(page).to have_content('Rapport en cours de génération')
      
      # Wait for job to complete (in test, it's synchronous)
      expect(page).to have_content('Rapport Mensuel - Décembre 2025')
      
      # Download in different formats
      click_link 'Télécharger PDF'
      expect(page.response_headers['Content-Type']).to include('application/pdf')
    end
  end
  
  describe 'Project Overview and Monitoring' do
    it 'monitors project progress across all departments' do
      visit immo_promo_engine.projects_path
      
      expect(page).to have_content('Projets Immobiliers')
      expect(page).to have_content('Jardins de Belleville')
      
      within "#project_#{project.id}" do
        expect(page).to have_content('En cours')
        click_link 'Voir détails'
      end
      
      # Project dashboard
      expect(page).to have_content('Vue d\'ensemble du projet')
      expect(page).to have_css('.progress-chart')
      expect(page).to have_content('Budget')
      expect(page).to have_content('Planning')
      expect(page).to have_content('Documents')
      
      # Check critical metrics
      within '.project-metrics' do
        expect(page).to have_content('Avancement global')
        expect(page).to have_content('Budget consommé')
        expect(page).to have_content('Jours restants')
      end
      
      # Navigate to project documents
      click_link 'Documents du projet'
      
      expect(page).to have_content('Documents - Jardins de Belleville')
      expect(page).to have_css('.document-grid')
    end
  end
  
  describe 'Compliance Monitoring' do
    it 'reviews compliance dashboard and takes action' do
      visit compliance_dashboard_path
      
      expect(page).to have_content('Tableau de bord Conformité')
      
      within '.compliance-summary' do
        expect(page).to have_content('Taux de conformité global')
        expect(page).to have_content('Documents non conformes')
        expect(page).to have_content('Audits à venir')
      end
      
      # Check alerts
      within '.compliance-alerts' do
        expect(page).to have_content('Alertes Conformité')
        
        # Click on a specific alert
        first('.alert-item').click
      end
      
      # Take corrective action
      expect(page).to have_content('Détails de l\'alerte')
      click_button 'Assigner à l\'équipe juridique'
      
      expect(page).to have_content('Alerte assignée avec succès')
    end
  end
  
  describe 'Team Performance Review' do
    it 'reviews team performance metrics' do
      visit resources_path
      
      expect(page).to have_content('Gestion des Ressources')
      
      # View capacity dashboard
      click_link 'Tableau de bord capacité'
      
      within '.capacity-overview' do
        expect(page).to have_content('Utilisation globale')
        expect(page).to have_content('Ressources disponibles')
        expect(page).to have_css('.capacity-chart')
      end
      
      # Check individual performance
      click_link 'Performance individuelle'
      
      within '.performance-table' do
        expect(page).to have_content('Taux d\'occupation')
        expect(page).to have_content('Projets assignés')
        expect(page).to have_content('Efficacité')
      end
    end
  end
  
  describe 'Strategic Decision Making' do
    it 'uses analytics for strategic decisions' do
      visit budget_dashboard_path
      
      expect(page).to have_content('Tableau de bord Financier')
      
      # Review financial KPIs
      within '.financial-kpis' do
        expect(page).to have_content('ROI Global')
        expect(page).to have_content('Marge Nette')
        expect(page).to have_content('Cash Flow')
      end
      
      # Drill down into specific project
      select 'Jardins de Belleville', from: 'project_filter'
      click_button 'Appliquer'
      
      # Review project-specific metrics
      expect(page).to have_content('Analyse Financière - Jardins de Belleville')
      expect(page).to have_css('.variance-analysis')
      
      # Export data for board presentation
      click_link 'Exporter pour présentation'
      
      expect(page).to have_content('Export en cours')
    end
  end
  
  describe 'Mobile Responsiveness' do
    it 'works seamlessly on tablet for on-site visits', js: true do
      # Simulate iPad viewport
      page.driver.browser.manage.window.resize_to(768, 1024)
      
      visit root_path
      
      # Mobile navigation should work
      expect(page).to have_css('.mobile-menu-toggle')
      find('.mobile-menu-toggle').click
      
      expect(page).to have_css('.mobile-menu', visible: true)
      
      # Quick actions should be accessible
      within '.mobile-menu' do
        click_link 'Validations urgentes'
      end
      
      expect(page).to have_content('Validations en attente')
      
      # Document preview should work in mobile
      first('.document-item').click
      expect(page).to have_css('.document-preview-mobile')
    end
  end
end