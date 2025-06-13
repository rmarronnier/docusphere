require 'rails_helper'

RSpec.describe 'Commercial User Journey', type: :system do
  let(:organization) { create(:organization, name: 'Meridia Group') }
  let(:commercial) { create(:user, first_name: 'Sophie', last_name: 'Martin', email: 'sophie.martin@meridia.fr', organization: organization) }
  let!(:client) { create(:client, name: 'ACME Corp', status: 'active', organization: organization) }
  let!(:prospect) { create(:client, name: 'TechStart SAS', status: 'prospect', organization: organization) }
  let!(:project) { create(:immo_promo_project, name: 'Business Center Alpha', organization: organization) }
  
  before do
    commercial.update!(role: :user)
    sign_in commercial
  end
  
  describe 'Commercial Dashboard' do
    it 'views sales-focused dashboard' do
      visit root_path
      
      expect(page).to have_content('Tableau de bord Commercial')
      
      within '.client-documents-widget' do
        expect(page).to have_content('Documents Clients')
        expect(page).to have_content('Propositions actives')
        expect(page).to have_content('Contrats en cours')
      end
      
      within '.quick-actions-widget' do
        expect(page).to have_content('Nouvelle proposition')
        expect(page).to have_content('Envoyer documentation')
        expect(page).to have_content('Planifier rendez-vous')
      end
    end
  end
  
  describe 'Client Management' do
    it 'manages client portfolio' do
      visit clients_path
      
      expect(page).to have_content('Gestion Clients')
      expect(page).to have_content('ACME Corp')
      expect(page).to have_content('TechStart SAS')
      
      # Filter by status
      select 'Prospects', from: 'filter'
      click_button 'Filtrer'
      
      expect(page).to have_content('TechStart SAS')
      expect(page).not_to have_content('ACME Corp')
      
      # View client details
      click_link 'TechStart SAS'
      
      expect(page).to have_content('Fiche Client')
      expect(page).to have_content('Statut: Prospect')
      expect(page).to have_css('.client-timeline')
    end
    
    it 'creates new client' do
      visit new_client_path
      
      fill_in 'Nom', with: 'Innovation Labs'
      fill_in 'Email', with: 'contact@innovationlabs.fr'
      fill_in 'Téléphone', with: '01 23 45 67 89'
      fill_in 'Adresse', with: '123 rue de l\'Innovation'
      fill_in 'Ville', with: 'Paris'
      fill_in 'Code postal', with: '75008'
      select 'Entreprise', from: 'Type'
      select 'Prospect', from: 'Statut'
      fill_in 'Contact principal', with: 'Jean Dupont'
      fill_in 'Email contact', with: 'j.dupont@innovationlabs.fr'
      
      click_button 'Créer client'
      
      expect(page).to have_content('Client créé avec succès')
      expect(page).to have_content('Innovation Labs')
      expect(page).to have_content('Dossier client créé')
    end
  end
  
  describe 'Proposal Creation and Management' do
    it 'creates commercial proposal for prospect' do
      visit client_path(prospect)
      
      click_link 'Nouvelle proposition'
      
      within '.proposal-form' do
        fill_in 'Titre', with: 'Proposition commerciale - Bureaux 500m²'
        select 'Business Center Alpha', from: 'Projet'
        fill_in 'Surface', with: '500'
        select 'Location', from: 'Type de contrat'
        fill_in 'Prix mensuel', with: '25000'
        fill_in 'Durée', with: '36'
        
        # Add options
        check 'Parking (50 places)'
        check 'Services conciergerie'
        
        # Commercial conditions
        fill_in 'Remise', with: '5'
        fill_in 'Franchise', with: '3'
        
        # Attach documents
        attach_file 'Plans', Rails.root.join('spec/fixtures/files/plan_bureaux.pdf')
        attach_file 'Brochure', Rails.root.join('spec/fixtures/files/brochure_alpha.pdf')
        
        click_button 'Créer proposition'
      end
      
      expect(page).to have_content('Proposition créée avec succès')
      expect(page).to have_content('Proposition commerciale - Bureaux 500m²')
      expect(page).to have_content('23 750 €/mois') # With 5% discount
    end
    
    it 'sends proposal to client' do
      proposal = create(:proposal, client: prospect, created_by: commercial)
      
      visit proposal_path(proposal)
      
      click_button 'Envoyer au client'
      
      within '.send-proposal-modal' do
        fill_in 'Message personnalisé', with: 'Bonjour, veuillez trouver ci-joint notre proposition...'
        fill_in 'CC', with: 'manager@meridia.fr'
        check 'Demander accusé de réception'
        
        click_button 'Envoyer'
      end
      
      expect(page).to have_content('Proposition envoyée avec succès')
      expect(page).to have_content('Statut: Envoyée')
      expect(page).to have_content('Accusé de réception en attente')
    end
  end
  
  describe 'Contract Management' do
    it 'converts accepted proposal to contract' do
      accepted_proposal = create(:proposal, client: client, status: 'accepted')
      
      visit proposal_path(accepted_proposal)
      
      click_button 'Convertir en contrat'
      
      within '.contract-conversion-form' do
        fill_in 'Date de début', with: 1.month.from_now
        fill_in 'Garantie', with: '75000'
        select 'Virement', from: 'Mode de paiement'
        
        # Legal clauses
        check 'Clause résolutoire standard'
        check 'Indexation ICC'
        
        click_button 'Générer contrat'
      end
      
      expect(page).to have_content('Contrat généré avec succès')
      expect(page).to have_content('En attente de signature')
      expect(page).to have_css('.signature-workflow')
    end
    
    it 'tracks contract signatures' do
      contract = create(:contract, client: client, status: 'pending_signature')
      
      visit contract_path(contract)
      
      expect(page).to have_content('Workflow de signature')
      expect(page).to have_content('0/2 signatures')
      
      # Simulate client signature
      within '.signature-tracking' do
        expect(page).to have_content('Client: En attente')
        expect(page).to have_content('Meridia: En attente')
      end
      
      # Send reminder
      click_button 'Envoyer rappel'
      
      expect(page).to have_content('Rappel envoyé au client')
    end
  end
  
  describe 'Document Sharing with Clients' do
    it 'shares project documents with client' do
      document = create(:document, title: 'Plaquette commerciale', documentable: project)
      
      visit project_documents_path(project)
      
      within "#document_#{document.id}" do
        click_button 'Partager'
      end
      
      within '.share-modal' do
        select 'ACME Corp', from: 'Client'
        fill_in 'Message', with: 'Voici la plaquette commerciale du projet'
        fill_in 'Valide jusqu\'au', with: 30.days.from_now
        check 'Autoriser le téléchargement'
        check 'Notifier par email'
        
        click_button 'Partager'
      end
      
      expect(page).to have_content('Document partagé avec succès')
      expect(page).to have_content('Lien de partage généré')
      
      # Copy share link
      click_button 'Copier le lien'
      expect(page).to have_content('Lien copié')
    end
    
    it 'manages shared document access' do
      visit client_documents_path
      
      expect(page).to have_content('Documents partagés')
      
      within '.shared-documents-table' do
        expect(page).to have_content('Plaquette commerciale')
        expect(page).to have_content('ACME Corp')
        expect(page).to have_content('Actif')
        
        # Revoke access
        click_button 'Révoquer'
      end
      
      expect(page).to have_content('Accès révoqué')
    end
  end
  
  describe 'Sales Pipeline Management' do
    it 'tracks opportunities through sales pipeline' do
      visit immo_promo_engine.commercial_dashboard_index_path
      
      expect(page).to have_content('Pipeline Commercial')
      
      within '.pipeline-kanban' do
        expect(page).to have_css('.pipeline-stage', count: 5)
        expect(page).to have_content('Prospect')
        expect(page).to have_content('Proposition')
        expect(page).to have_content('Négociation')
        expect(page).to have_content('Signature')
        expect(page).to have_content('Gagné')
      end
      
      # Drag opportunity to next stage
      opportunity = find('.opportunity-card', text: 'TechStart SAS')
      negotiation_stage = find('.pipeline-stage', text: 'Négociation')
      
      opportunity.drag_to(negotiation_stage)
      
      expect(page).to have_content('Opportunité mise à jour')
      expect(negotiation_stage).to have_content('TechStart SAS')
    end
  end
  
  describe 'Client Communication Tracking' do
    it 'logs client interactions' do
      visit client_path(client)
      
      click_link 'Nouvelle interaction'
      
      within '.interaction-form' do
        select 'Appel téléphonique', from: 'Type'
        fill_in 'Durée', with: '30'
        fill_in 'Objet', with: 'Suivi proposition commerciale'
        fill_in 'Notes', with: 'Client intéressé, demande des précisions sur les conditions de paiement'
        fill_in 'Prochaine action', with: 'Envoyer simulation financière détaillée'
        fill_in 'Date de rappel', with: 3.days.from_now
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Interaction enregistrée')
      
      within '.client-timeline' do
        expect(page).to have_content('Appel téléphonique - 30 min')
        expect(page).to have_content('Suivi proposition commerciale')
      end
      
      # Check reminder is set
      visit root_path
      within '.reminders-widget' do
        expect(page).to have_content('Envoyer simulation financière')
      end
    end
  end
  
  describe 'Reporting and Analytics' do
    it 'generates commercial performance report' do
      visit reports_path
      
      click_link 'Nouveau rapport commercial'
      
      within '.report-form' do
        select 'Performance commerciale', from: 'Type'
        fill_in 'Période début', with: Date.current.beginning_of_month
        fill_in 'Période fin', with: Date.current.end_of_month
        check 'Inclure pipeline'
        check 'Inclure taux conversion'
        check 'Inclure CA par commercial'
        
        click_button 'Générer'
      end
      
      expect(page).to have_content('Rapport Performance Commerciale')
      expect(page).to have_css('.conversion-funnel-chart')
      expect(page).to have_content('Taux de conversion: 23%')
      expect(page).to have_content('CA mensuel')
      
      # Export report
      click_link 'Exporter PowerPoint'
      expect(page.response_headers['Content-Type']).to include('application/vnd.openxmlformats')
    end
  end
  
  describe 'Mobile CRM Usage' do
    it 'manages clients on mobile during visits', js: true do
      page.driver.browser.manage.window.resize_to(375, 812)
      
      visit clients_path
      
      # Quick client search
      fill_in 'search', with: 'ACME'
      
      expect(page).to have_content('ACME Corp')
      click_link 'ACME Corp'
      
      # Quick actions visible
      expect(page).to have_css('.mobile-quick-actions')
      
      # Log visit
      within '.mobile-quick-actions' do
        click_button 'Check-in visite'
      end
      
      expect(page).to have_content('Check-in enregistré')
      expect(page).to have_content('Visite en cours')
      
      # Quick note
      click_button 'Note rapide'
      
      within '.quick-note-modal' do
        fill_in 'note', with: 'Client intéressé par étage supplémentaire'
        click_button 'Sauvegarder'
      end
      
      expect(page).to have_content('Note ajoutée')
      
      # End visit
      click_button 'Terminer visite'
      
      within '.visit-summary-modal' do
        fill_in 'Résumé', with: 'Visite positive, suite à donner'
        select 'Chaud', from: 'Température'
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Visite enregistrée')
    end
  end
end