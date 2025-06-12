require 'rails_helper'

RSpec.describe 'Juridique User Journey', type: :system do
  let(:organization) { create(:organization, name: 'Meridia Group') }
  let(:juridique) { create(:user, name: 'Claire Dumont', email: 'claire.dumont@meridia.fr', organization: organization) }
  let!(:contract) { create(:contract, title: 'Contrat de location Business Center', status: 'pending_review', organization: organization) }
  let!(:deadline) { create(:legal_deadline, title: 'Renouvellement assurance RC', due_date: 15.days.from_now, organization: organization) }
  
  before do
    juridique.add_role(:juridique)
    sign_in juridique
  end
  
  describe 'Legal Dashboard Overview' do
    it 'views legal-specific dashboard' do
      visit root_path
      
      expect(page).to have_content('Tableau de bord Juridique')
      
      within '.compliance-alerts-widget' do
        expect(page).to have_content('Alertes Conformité')
        expect(page).to have_content('Échéances légales')
        expect(page).to have_css('.deadline-countdown')
      end
      
      within '.recent-activity-widget' do
        expect(page).to have_content('Contrats à réviser')
        expect(page).to have_content('Validations juridiques')
      end
    end
  end
  
  describe 'Contract Review Process' do
    it 'reviews and validates legal contract' do
      visit legal_contracts_path
      
      expect(page).to have_content('Contrats - Révision Juridique')
      expect(page).to have_content('Contrat de location Business Center')
      
      within "#contract_#{contract.id}" do
        expect(page).to have_content('En attente de révision')
        click_link 'Examiner'
      end
      
      # Contract details page
      expect(page).to have_content('Analyse Juridique')
      expect(page).to have_css('.contract-clauses')
      expect(page).to have_css('.risk-assessment')
      
      # Review checklist
      click_link 'Démarrer révision'
      
      within '.legal-review-checklist' do
        check 'Clauses générales conformes'
        check 'Conditions de paiement vérifiées'
        check 'Clauses de résiliation acceptables'
        check 'Garanties suffisantes'
        
        # Flag issue
        uncheck 'Clause de non-concurrence'
        fill_in 'Commentaire non-concurrence', with: 'Périmètre géographique trop large, limiter à 5km'
        
        select 'Faible', from: 'Niveau de risque'
        fill_in 'Recommandations', with: 'Modifier clause 12.3 pour limiter la non-concurrence à 5km du site'
        
        click_button 'Valider avec réserves'
      end
      
      expect(page).to have_content('Validation juridique enregistrée')
      expect(page).to have_content('Statut: Validé avec réserves')
      expect(contract.reload.legal_status).to eq('approved_with_conditions')
    end
    
    it 'uses clause library for contract drafting' do
      visit new_legal_contract_path
      
      fill_in 'Titre', with: 'Contrat de prestation de services'
      select 'ACME Corp', from: 'Client'
      select 'Services', from: 'Type de contrat'
      
      # Add standard clauses
      click_link 'Bibliothèque de clauses'
      
      within '.clause-library-modal' do
        check 'Confidentialité standard'
        check 'Propriété intellectuelle - Prestation'
        check 'RGPD - Sous-traitant'
        check 'Force majeure - COVID'
        
        click_button 'Ajouter les clauses sélectionnées'
      end
      
      expect(page).to have_content('4 clauses ajoutées')
      
      within '.contract-clauses-editor' do
        expect(page).to have_content('CONFIDENTIALITÉ')
        expect(page).to have_content('PROPRIÉTÉ INTELLECTUELLE')
        expect(page).to have_content('PROTECTION DES DONNÉES')
        expect(page).to have_content('FORCE MAJEURE')
      end
      
      # Customize clause
      within '.clause-item', text: 'CONFIDENTIALITÉ' do
        click_link 'Personnaliser'
        fill_in 'Durée de confidentialité', with: '5 ans'
        click_button 'Appliquer'
      end
      
      fill_in 'Droit applicable', with: 'Droit français'
      fill_in 'Juridiction', with: 'Tribunaux de Paris'
      
      click_button 'Créer contrat'
      
      expect(page).to have_content('Contrat juridique créé avec succès')
    end
  end
  
  describe 'Legal Deadline Management' do
    it 'manages legal deadlines and compliance' do
      visit legal_deadlines_path
      
      expect(page).to have_content('Échéances Légales')
      expect(page).to have_content('Renouvellement assurance RC')
      
      # Calendar view
      click_link 'Vue calendrier'
      
      expect(page).to have_css('.legal-calendar')
      expect(page).to have_css('.deadline-event', text: 'Assurance RC')
      
      # Create new deadline
      click_link 'Nouvelle échéance'
      
      within '.deadline-form' do
        fill_in 'Titre', with: 'Dépôt comptes annuels'
        select 'Déclaration réglementaire', from: 'Type'
        fill_in 'Date limite', with: 3.months.from_now
        select 'Haute', from: 'Priorité'
        check 'Récurrent'
        select 'Annuel', from: 'Périodicité'
        fill_in 'Rappels', with: '30,15,7,1'
        fill_in 'Référence légale', with: 'Article L232-1 Code de commerce'
        fill_in 'Pénalités', with: 'Amende de 1500€ + astreinte journalière'
        
        click_button 'Créer échéance'
      end
      
      expect(page).to have_content('Échéance légale créée avec succès')
      expect(page).to have_content('Rappels programmés: 30j, 15j, 7j, 1j')
    end
    
    it 'completes legal deadline with documentation' do
      visit legal_deadline_path(deadline)
      
      expect(page).to have_content('15 jours restants')
      
      click_button 'Marquer comme complétée'
      
      within '.completion-modal' do
        fill_in 'Notes de complétion', with: 'Assurance RC renouvelée pour 2025-2026'
        attach_file 'Documents justificatifs', [
          Rails.root.join('spec/fixtures/files/attestation_rc_2025.pdf'),
          Rails.root.join('spec/fixtures/files/police_assurance_2025.pdf')
        ]
        
        click_button 'Confirmer complétion'
      end
      
      expect(page).to have_content('Échéance marquée comme complétée')
      expect(page).to have_content('Complétée le')
      expect(page).to have_css('.supporting-documents', count: 2)
    end
  end
  
  describe 'Compliance Dashboard' do
    it 'monitors global compliance status' do
      visit compliance_dashboard_legal_contracts_path
      
      expect(page).to have_content('Tableau de bord Conformité')
      
      within '.compliance-metrics' do
        expect(page).to have_content('Taux de conformité global')
        expect(page).to have_content('92%')
        expect(page).to have_content('Conformité RGPD')
        expect(page).to have_content('Violations réglementaires: 0')
      end
      
      within '.upcoming-audits' do
        expect(page).to have_content('Audits à venir')
        expect(page).to have_content('Audit RGPD - Janvier 2025')
      end
      
      # Drill down into specific area
      click_link 'Détails RGPD'
      
      expect(page).to have_content('Conformité RGPD Détaillée')
      expect(page).to have_css('.gdpr-checklist')
      expect(page).to have_content('Registre des traitements: ✓')
      expect(page).to have_content('DPO désigné: ✓')
      expect(page).to have_content('Analyse d\'impact: En cours')
      
      # Take corrective action
      within '.gdpr-action-items' do
        click_link 'Finaliser analyse d\'impact'
      end
      
      expect(page).to have_content('Analyse d\'Impact (PIA)')
    end
  end
  
  describe 'Legal Risk Assessment' do
    it 'assesses and manages legal risks' do
      visit legal_contracts_path
      
      click_link 'Évaluation des risques'
      
      expect(page).to have_content('Matrice des Risques Juridiques')
      expect(page).to have_css('.risk-matrix-grid')
      
      within '.high-risk-contracts' do
        expect(page).to have_content('Contrats à risque élevé')
        
        first('.risk-contract-item').click
      end
      
      expect(page).to have_content('Analyse des Risques')
      expect(page).to have_content('Score de risque: 7.5/10')
      
      within '.risk-factors' do
        expect(page).to have_content('Absence de clause de limitation de responsabilité')
        expect(page).to have_content('Juridiction étrangère')
        expect(page).to have_content('Pénalités excessives')
      end
      
      # Add mitigation measures
      click_button 'Ajouter mesures d\'atténuation'
      
      within '.mitigation-form' do
        fill_in 'Mesure', with: 'Négocier plafond de responsabilité à 100k€'
        select 'Haute', from: 'Priorité'
        fill_in 'Responsable', with: 'Claire Dumont'
        fill_in 'Date limite', with: 1.week.from_now
        
        click_button 'Ajouter'
      end
      
      expect(page).to have_content('Mesure d\'atténuation ajoutée')
      expect(page).to have_content('Score de risque recalculé: 5.5/10')
    end
  end
  
  describe 'Electronic Signature Workflow' do
    it 'manages electronic signature process' do
      contract_to_sign = create(:contract, title: 'Contrat important', status: 'ready_for_signature')
      
      visit legal_contract_path(contract_to_sign)
      
      click_button 'Lancer signature électronique'
      
      within '.signature-setup-modal' do
        # Add signatories
        fill_in 'Signataire 1 email', with: 'director@meridia.fr'
        select 'Direction Meridia', from: 'Signataire 1 rôle'
        
        fill_in 'Signataire 2 email', with: 'client@acme.fr'
        select 'Client', from: 'Signataire 2 rôle'
        
        select 'Séquentiel', from: 'Ordre de signature'
        fill_in 'Message', with: 'Merci de procéder à la signature du contrat'
        
        check 'Certificat qualifié'
        check 'Horodatage qualifié'
        
        click_button 'Envoyer pour signature'
      end
      
      expect(page).to have_content('Processus de signature lancé')
      expect(page).to have_content('En attente: director@meridia.fr')
      
      within '.signature-tracking' do
        expect(page).to have_css('.signature-timeline')
        expect(page).to have_content('0/2 signatures')
      end
    end
  end
  
  describe 'Legal Reporting' do
    it 'generates legal department report' do
      visit legal_contracts_path
      
      click_link 'Générer rapport juridique'
      
      within '.legal-report-form' do
        select 'Rapport mensuel juridique', from: 'Type'
        fill_in 'Période début', with: Date.current.beginning_of_month
        fill_in 'Période fin', with: Date.current.end_of_month
        
        check 'Synthèse des contrats'
        check 'Litiges en cours'
        check 'Conformité réglementaire'
        check 'Échéances à venir'
        
        click_button 'Générer'
      end
      
      expect(page).to have_content('Rapport Juridique - Décembre 2025')
      
      within '.report-content' do
        expect(page).to have_content('Synthèse Exécutive')
        expect(page).to have_content('15 contrats révisés')
        expect(page).to have_content('3 nouveaux contrats')
        expect(page).to have_content('0 litiges actifs')
        expect(page).to have_content('Taux conformité: 98%')
      end
      
      # Export for board
      click_link 'Exporter PDF'
      expect(page.response_headers['Content-Type']).to include('application/pdf')
    end
  end
  
  describe 'Contract Template Management' do
    it 'creates and manages contract templates' do
      visit legal_contracts_path
      
      click_link 'Modèles de contrats'
      
      click_link 'Nouveau modèle'
      
      within '.template-form' do
        fill_in 'Nom du modèle', with: 'Location bureaux standard'
        select 'Location commerciale', from: 'Catégorie'
        
        # Build template with variables
        fill_in 'Contenu', with: <<~TEMPLATE
          CONTRAT DE LOCATION DE BUREAUX
          
          Entre {{BAILLEUR_NOM}}, ci-après le "Bailleur"
          Et {{LOCATAIRE_NOM}}, ci-après le "Locataire"
          
          Article 1: Objet
          Location de {{SURFACE}}m² de bureaux situés {{ADRESSE}}
          
          Article 2: Loyer
          Loyer mensuel: {{LOYER_MENSUEL}}€ HT
        TEMPLATE
        
        # Define variables
        click_button 'Ajouter variable'
        fill_in 'Variable', with: 'BAILLEUR_NOM'
        select 'Texte', from: 'Type'
        fill_in 'Par défaut', with: 'Meridia Group SAS'
        
        click_button 'Créer modèle'
      end
      
      expect(page).to have_content('Modèle créé avec succès')
      expect(page).to have_content('Location bureaux standard')
      
      # Test template
      click_button 'Tester le modèle'
      
      within '.template-test-modal' do
        fill_in 'LOCATAIRE_NOM', with: 'Test Company'
        fill_in 'SURFACE', with: '250'
        fill_in 'LOYER_MENSUEL', with: '12500'
        
        click_button 'Générer aperçu'
      end
      
      expect(page).to have_content('Entre Meridia Group SAS')
      expect(page).to have_content('Et Test Company')
      expect(page).to have_content('Location de 250m² de bureaux')
    end
  end
end