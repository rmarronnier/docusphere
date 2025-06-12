require 'rails_helper'

RSpec.describe 'Cross-Profile Collaboration Journey', type: :system do
  let(:organization) { create(:organization, name: 'Meridia Group') }
  
  # Users
  let(:direction) { create(:user, name: 'Marie Dubois', organization: organization) }
  let(:chef_projet) { create(:user, name: 'Julien Leroy', organization: organization) }
  let(:commercial) { create(:user, name: 'Sophie Martin', organization: organization) }
  let(:juridique) { create(:user, name: 'Claire Dumont', organization: organization) }
  let(:finance) { create(:user, name: 'Pierre Lambert', organization: organization) }
  
  # Shared data
  let!(:project) { create(:project, name: 'Business Center Alpha', organization: organization, project_manager: chef_projet) }
  let!(:client) { create(:client, name: 'Global Tech Solutions', organization: organization) }
  let!(:contract_draft) { create(:document, title: 'Contrat de location - Draft v1', documentable: project, uploaded_by: commercial) }
  
  before do
    direction.add_role(:direction)
    chef_projet.add_role(:chef_projet)
    commercial.add_role(:commercial)
    juridique.add_role(:juridique)
    finance.add_role(:finance)
  end
  
  describe 'New Client Contract Workflow' do
    it 'collaborates on new client contract from prospect to signature' do
      # Step 1: Commercial creates opportunity
      sign_in commercial
      visit new_proposal_path
      
      fill_in 'Titre', with: 'Location 1500m² - Business Center Alpha'
      select 'Global Tech Solutions', from: 'Client'
      select 'Business Center Alpha', from: 'Projet'
      fill_in 'Surface', with: '1500'
      fill_in 'Prix mensuel', with: '75000'
      fill_in 'Durée', with: '60'
      
      click_button 'Créer proposition'
      
      proposal = Proposal.last
      expect(page).to have_content('Proposition créée avec succès')
      
      # Commercial requests project manager input
      click_button 'Demander validation technique'
      select 'Julien Leroy', from: 'Destinataire'
      fill_in 'Message', with: 'Merci de valider la disponibilité de l\'espace'
      click_button 'Envoyer'
      
      sign_out commercial
      
      # Step 2: Chef de projet validates technical aspects
      sign_in chef_projet
      visit root_path
      
      within '.notifications-widget' do
        click_link 'Validation technique requise'
      end
      
      expect(page).to have_content('Location 1500m² - Business Center Alpha')
      
      # Check availability
      click_link 'Vérifier disponibilité'
      
      within '.space-availability-checker' do
        expect(page).to have_content('Étage 3-4: Disponible')
        expect(page).to have_content('1500m² contigus')
        check 'Espace validé'
        fill_in 'Commentaire', with: 'Espace disponible, travaux d\'aménagement possibles'
        click_button 'Valider'
      end
      
      # Add technical documents
      click_button 'Ajouter documents techniques'
      attach_file 'documents[]', [
        Rails.root.join('spec/fixtures/files/plan_etage_3_4.pdf'),
        Rails.root.join('spec/fixtures/files/specs_techniques.pdf')
      ]
      click_button 'Téléverser'
      
      expect(page).to have_content('Validation technique complétée')
      
      sign_out chef_projet
      
      # Step 3: Commercial converts to contract and requests legal review
      sign_in commercial
      visit proposal_path(proposal)
      
      expect(page).to have_content('Validation technique: ✓')
      
      # Client accepts proposal
      click_button 'Marquer comme acceptée'
      
      # Convert to contract
      click_button 'Convertir en contrat'
      
      within '.contract-conversion-form' do
        fill_in 'Date de début', with: 2.months.from_now
        click_button 'Générer contrat'
      end
      
      contract = Contract.last
      
      # Request legal review
      click_button 'Demander révision juridique'
      select 'Claire Dumont', from: 'Juriste'
      fill_in 'Notes', with: 'Client demande clause de sortie anticipée après 36 mois'
      click_button 'Envoyer'
      
      sign_out commercial
      
      # Step 4: Juridique reviews and adds legal clauses
      sign_in juridique
      visit root_path
      
      within '.recent-activity-widget' do
        click_link 'Nouveau contrat à réviser'
      end
      
      expect(page).to have_content('Contrat de location - Global Tech Solutions')
      expect(page).to have_content('Note: Client demande clause de sortie anticipée')
      
      # Start legal review
      click_button 'Démarrer révision juridique'
      
      within '.legal-review-form' do
        # Add required clauses
        check 'Clause de sortie anticipée'
        fill_in 'Conditions sortie', with: 'Préavis 6 mois, indemnité 3 mois de loyer'
        
        check 'Garantie bancaire'
        fill_in 'Montant garantie', with: '225000'
        
        check 'Indexation loyer'
        select 'ILAT', from: 'Indice'
        
        # Risk assessment
        select 'Moyen', from: 'Niveau de risque'
        fill_in 'Points d\'attention', with: 'Clause de sortie anticipée à surveiller'
        
        click_button 'Valider juridiquement'
      end
      
      expect(page).to have_content('Révision juridique complétée')
      
      # Generate final contract
      click_button 'Générer contrat final'
      
      expect(page).to have_content('Contrat finalisé')
      expect(page).to have_content('document_contract_final.pdf')
      
      sign_out juridique
      
      # Step 5: Finance validates financial terms
      sign_in finance
      visit contract_path(contract)
      
      click_button 'Valider conditions financières'
      
      within '.financial-validation-form' do
        expect(page).to have_content('Loyer mensuel: 75 000€')
        expect(page).to have_content('Garantie: 225 000€')
        
        # Financial analysis
        fill_in 'Score crédit client', with: '8/10'
        check 'Garantie bancaire vérifiée'
        check 'Conditions de paiement acceptables'
        fill_in 'Commentaire', with: 'Client solvable, conditions conformes aux standards'
        
        click_button 'Approuver'
      end
      
      expect(page).to have_content('Validation financière complétée')
      
      sign_out finance
      
      # Step 6: Direction gives final approval
      sign_in direction
      visit contract_path(contract)
      
      expect(page).to have_content('Validations complétées')
      expect(page).to have_css('.validation-status', text: 'Commercial: ✓')
      expect(page).to have_css('.validation-status', text: 'Technique: ✓')
      expect(page).to have_css('.validation-status', text: 'Juridique: ✓')
      expect(page).to have_css('.validation-status', text: 'Finance: ✓')
      
      # Final review
      click_button 'Révision finale Direction'
      
      within '.director-review-modal' do
        expect(page).to have_content('Montant total: 4 500 000€')
        expect(page).to have_content('ROI estimé: 18%')
        
        check 'Approuvé par la Direction'
        fill_in 'Commentaire', with: 'Excellent client, conditions négociées favorables'
        
        click_button 'Approuver et lancer signature'
      end
      
      expect(page).to have_content('Contrat approuvé')
      expect(page).to have_content('Processus de signature lancé')
      
      # Contract is now ready for signature
      expect(contract.reload.status).to eq('pending_signature')
      expect(contract.approvals.count).to eq(5)
    end
  end
  
  describe 'Urgent Document Validation Chain' do
    it 'handles urgent cross-department validation efficiently' do
      urgent_doc = create(:document, 
        title: 'Permis de construire modificatif - URGENT',
        documentable: project,
        uploaded_by: chef_projet
      )
      
      # Chef de projet initiates urgent validation
      sign_in chef_projet
      visit ged_document_path(urgent_doc)
      
      click_button 'Validation urgente'
      
      within '.urgent-validation-modal' do
        check 'Juridique - Claire Dumont'
        check 'Direction - Marie Dubois'
        fill_in 'Délai', with: '4 heures'
        fill_in 'Raison urgence', with: 'Dépôt préfecture avant 17h aujourd\'hui'
        check 'Notifier par SMS'
        
        click_button 'Lancer validation urgente'
      end
      
      expect(page).to have_content('Validation urgente lancée')
      expect(page).to have_css('.countdown-timer')
      
      sign_out chef_projet
      
      # Juridique receives and handles urgent request
      sign_in juridique
      
      # Simulating SMS notification leading to quick login
      visit root_path
      
      within '.urgent-alerts' do
        expect(page).to have_content('URGENT: Permis de construire')
        expect(page).to have_css('.time-remaining', text: /3h 5\d/)
        click_link 'Traiter maintenant'
      end
      
      # Quick validation
      within '.quick-validation-form' do
        check 'Conforme aux exigences légales'
        check 'Modifications mineures acceptables'
        fill_in 'Note', with: 'RAS sur le plan juridique'
        click_button 'Valider'
      end
      
      expect(page).to have_content('Validation juridique complétée')
      
      sign_out juridique
      
      # Direction completes the chain
      sign_in direction
      visit root_path
      
      within '.urgent-alerts' do
        click_link 'URGENT: Permis de construire'
      end
      
      expect(page).to have_content('Validation juridique: ✓')
      
      click_button 'Approuver'
      fill_in 'Commentaire', with: 'Approuvé pour dépôt immédiat'
      click_button 'Confirmer'
      
      expect(page).to have_content('Document approuvé')
      expect(page).to have_content('Toutes les validations complétées')
      
      # System notifies original requester
      sign_out direction
      sign_in chef_projet
      visit root_path
      
      within '.notifications' do
        expect(page).to have_content('Validation complétée: Permis de construire')
      end
    end
  end
  
  describe 'Multi-Department Project Status Meeting' do
    it 'prepares and shares project status across departments' do
      # Finance prepares budget status
      sign_in finance
      visit immo_promo_engine.project_budget_path(project)
      
      click_button 'Générer rapport budgétaire'
      
      within '.budget-report-form' do
        check 'Inclure variance analysis'
        check 'Inclure cash flow'
        check 'Inclure prévisions'
        click_button 'Générer'
      end
      
      budget_report = Document.last
      
      # Share with meeting participants
      click_button 'Partager pour réunion'
      check 'Direction'
      check 'Chef de projet'
      check 'Commercial'
      fill_in 'Note', with: 'Budget report pour réunion de suivi'
      click_button 'Partager'
      
      sign_out finance
      
      # Chef de projet prepares technical status
      sign_in chef_projet
      visit immo_promo_engine.project_path(project)
      
      click_button 'Rapport d\'avancement'
      
      within '.progress-report-form' do
        fill_in 'Avancement global', with: '42'
        fill_in 'Milestone atteints', with: 'Terrassement complété, Fondations en cours'
        fill_in 'Risques', with: 'Retard potentiel approvisionnement acier'
        fill_in 'Actions', with: 'Meeting fournisseur programmé'
        
        click_button 'Générer rapport'
      end
      
      technical_report = Document.last
      
      sign_out chef_projet
      
      # Direction views consolidated status
      sign_in direction
      visit immo_promo_engine.project_path(project)
      
      click_link 'Vue consolidée'
      
      expect(page).to have_content('Tableau de bord exécutif')
      
      within '.executive-dashboard' do
        # Financial metrics
        expect(page).to have_content('Budget consommé: 42%')
        expect(page).to have_content('Variance: -2%')
        
        # Technical progress
        expect(page).to have_content('Avancement: 42%')
        expect(page).to have_content('En ligne avec planning')
        
        # Commercial status
        expect(page).to have_content('Taux de commercialisation: 65%')
        expect(page).to have_content('Pipeline: 8 prospects')
        
        # Key risks
        expect(page).to have_css('.risk-indicator', text: 'Approvisionnement acier')
      end
      
      # Create action items
      click_button 'Actions de la réunion'
      
      within '.meeting-actions-form' do
        # Action 1
        fill_in 'action_1', with: 'Sécuriser approvisionnement acier'
        select 'Julien Leroy', from: 'responsable_1'
        fill_in 'deadline_1', with: 1.week.from_now
        
        # Action 2
        fill_in 'action_2', with: 'Accélérer commercialisation étages 5-6'
        select 'Sophie Martin', from: 'responsable_2'
        fill_in 'deadline_2', with: 2.weeks.from_now
        
        click_button 'Enregistrer et notifier'
      end
      
      expect(page).to have_content('Actions enregistrées et notifications envoyées')
    end
  end
  
  describe 'Document Version Control Across Teams' do
    it 'manages document versions with multi-team input' do
      # Commercial creates initial version
      sign_in commercial
      visit ged_document_path(contract_draft)
      
      expect(page).to have_content('Version 1')
      
      # Edit document
      click_button 'Nouvelle version'
      
      within '.version-form' do
        attach_file 'Nouveau fichier', Rails.root.join('spec/fixtures/files/contract_v2.pdf')
        fill_in 'Commentaire version', with: 'Ajout conditions commerciales négociées'
        click_button 'Créer version'
      end
      
      expect(page).to have_content('Version 2 créée')
      
      # Request legal input
      click_button 'Demander révision'
      select 'Juridique', from: 'Service'
      fill_in 'Message', with: 'Merci de valider les nouvelles conditions'
      click_button 'Envoyer'
      
      sign_out commercial
      
      # Juridique creates new version with legal changes
      sign_in juridique
      visit ged_document_path(contract_draft)
      
      click_link 'Version 2'
      
      # Review changes
      click_button 'Comparer avec v1'
      
      within '.version-comparison' do
        expect(page).to have_content('Nouvelles conditions commerciales')
        expect(page).to have_css('.addition')
      end
      
      # Create new version with legal additions
      click_button 'Nouvelle version basée sur v2'
      
      within '.version-form' do
        attach_file 'Nouveau fichier', Rails.root.join('spec/fixtures/files/contract_v3_legal.pdf')
        fill_in 'Commentaire', with: 'Ajout clauses juridiques obligatoires'
        check 'Version majeure'
        click_button 'Créer version'
      end
      
      expect(page).to have_content('Version 3 créée')
      
      sign_out juridique
      
      # Direction reviews all versions
      sign_in direction
      visit ged_document_path(contract_draft)
      
      click_link 'Historique versions'
      
      within '.version-timeline' do
        expect(page).to have_content('v1 - Sophie Martin - Version initiale')
        expect(page).to have_content('v2 - Sophie Martin - Conditions commerciales')
        expect(page).to have_content('v3 - Claire Dumont - Clauses juridiques')
      end
      
      # Approve final version
      within '.version-3' do
        click_button 'Approuver comme version finale'
      end
      
      within '.approval-modal' do
        check 'Version validée pour signature'
        fill_in 'Commentaire', with: 'Version finale approuvée par la Direction'
        click_button 'Confirmer'
      end
      
      expect(page).to have_content('Version 3 marquée comme finale')
      expect(page).to have_css('.version-badge', text: 'FINALE')
      
      # Lock document
      click_button 'Verrouiller document'
      
      expect(page).to have_content('Document verrouillé')
      expect(page).not_to have_button('Nouvelle version')
    end
  end
end