require 'rails_helper'

RSpec.describe 'Document AI and Compliance Features', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  
  before do
    space.authorize_user(user, 'write', granted_by: admin)
  end
  
  describe 'AI Classification' do
    context 'automatic classification on upload' do
      it 'classifies a contract document' do
        login_as(user, scope: :user)
        visit ged_space_path(space)
        
        click_button 'Nouveau document'
        
        within '#upload-document-modal' do
          fill_in 'Titre', with: 'Contrat de prestation de services'
          fill_in 'Description', with: 'Contrat entre la société ABC et XYZ pour des services de consultation. Durée: 12 mois. Clause de confidentialité incluse.'
          attach_file 'document[file]', Rails.root.join('spec/fixtures/sample_document.pdf')
          click_button 'Uploader'
        end
        
        expect(page).to have_content('Document uploadé avec succès')
        
        document = Document.last
        
        # Wait for AI processing
        sleep 2
        document.reload
        
        # Check classification
        expect(document.ai_category).to eq('contract')
        expect(document.ai_confidence).to be > 0.5
        
        visit ged_document_path(document)
        
        # UI should show classification
        within '.ai-classification' do
          expect(page).to have_content('Type: Contrat')
          expect(page).to have_content('Confiance:')
          expect(page).to have_css('.confidence-high') if document.ai_confidence > 0.7
        end
        
        # Check auto-generated tags
        within '.document-tags' do
          expect(page).to have_content('type:contract')
        end
      end
      
      it 'classifies an invoice document' do
        login_as(user, scope: :user)
        
        visit ged_space_path(space)
        click_button 'Nouveau document'
        
        within '#upload-document-modal' do
          fill_in 'Titre', with: 'Facture N°2024-001'
          fill_in 'Description', with: 'Facture pour services rendus. Montant HT: 1000€, TVA 20%: 200€, Total TTC: 1200€. Échéance: 30 jours'
          attach_file 'document[file]', Rails.root.join('spec/fixtures/sample_invoice.pdf')
          click_button 'Uploader'
        end
        
        document = Document.last
        sleep 2
        document.reload
        
        expect(document.ai_category).to eq('invoice')
        
        # Check extracted entities
        expect(document.ai_entities).to include(
          hash_including('type' => 'amount', 'value' => match(/1200/))
        )
        
        visit ged_document_path(document)
        
        within '.extracted-entities' do
          expect(page).to have_content('Montants détectés')
          expect(page).to have_content('1200€')
        end
      end
      
      it 'extracts entities from documents' do
        document = create(:document, 
          space: space,
          uploaded_by: user,
          title: 'Contrat commercial',
          description: 'Contact: jean.dupont@example.com, Tel: 01 23 45 67 89. Référence: CTR-2024-001'
        )
        
        AiClassificationService.classify_document(document)
        document.reload
        
        login_as(user, scope: :user)
        visit ged_document_path(document)
        
        within '.extracted-entities' do
          expect(page).to have_content('Entités extraites')
          expect(page).to have_content('Email: jean.dupont@example.com')
          expect(page).to have_content('Téléphone: 01 23 45 67 89')
          expect(page).to have_content('Référence: CTR-2024-001')
        end
      end
    end
    
    context 'manual classification' do
      let(:document) { create(:document, space: space, uploaded_by: user) }
      
      it 'allows manual AI classification trigger' do
        login_as(user, scope: :user)
        visit ged_document_path(document)
        
        expect(page).not_to have_css('.ai-classification')
        
        click_button 'Classifier (IA)'
        
        expect(page).to have_content('Classification en cours...')
        
        # Wait for classification
        sleep 2
        
        expect(page).to have_css('.ai-classification')
        expect(page).to have_content('Classification terminée')
      end
    end
  end
  
  describe 'Regulatory Compliance' do
    context 'GDPR compliance' do
      let(:document) do
        create(:document,
          space: space,
          uploaded_by: user,
          title: 'Contrat de service',
          description: 'Contrat incluant traitement de données personnelles',
          ai_category: 'contract',
          extracted_text: 'Nom: Jean Dupont, Email: jean@example.com, Numéro de sécurité sociale: 123456789'
        )
      end
      
      it 'detects GDPR compliance issues' do
        login_as(user, scope: :user)
        visit ged_document_path(document)
        
        click_button 'Vérifier la conformité'
        
        expect(page).to have_content('Vérification en cours...')
        
        within '.compliance-results' do
          expect(page).to have_content('Score de conformité')
          expect(page).to have_css('.compliance-score.non-compliant')
          
          expect(page).to have_content('Violations détectées')
          expect(page).to have_content('GDPR/RGPD')
          expect(page).to have_content('Données personnelles non protégées')
          expect(page).to have_content('Aucune mention de consentement')
        end
        
        # Check remediation suggestions
        click_link 'Voir les recommandations'
        
        within '#remediation-modal' do
          expect(page).to have_content('Actions recommandées')
          expect(page).to have_content('Anonymiser ou chiffrer les données personnelles')
          expect(page).to have_content('Ajouter une clause de consentement RGPD')
        end
      end
    end
    
    context 'Contract compliance' do
      let(:document) do
        create(:document,
          space: space,
          uploaded_by: user,
          title: 'Contrat de vente',
          ai_category: 'contract',
          extracted_text: 'Contrat de vente entre parties. Prix: 10000€. Conditions de paiement: 30 jours.'
        )
      end
      
      it 'checks for mandatory contract clauses' do
        login_as(user, scope: :user)
        visit ged_document_path(document)
        
        click_button 'Vérifier la conformité'
        
        within '.compliance-results' do
          expect(page).to have_content('Clauses obligatoires manquantes')
          expect(page).to have_content('force majeure')
          expect(page).to have_content('résiliation')
          expect(page).to have_content('juridiction')
        end
      end
    end
    
    context 'Financial compliance' do
      let(:document) do
        create(:document,
          space: space,
          uploaded_by: user,
          title: 'Rapport financier',
          ai_category: 'financial',
          extracted_text: 'Transaction de 15000€ effectuée. Bénéficiaire: Société XYZ'
        )
      end
      
      it 'flags high-value transactions' do
        login_as(user, scope: :user)
        visit ged_document_path(document)
        
        click_button 'Vérifier la conformité'
        
        within '.compliance-results' do
          expect(page).to have_content('Transactions élevées détectées')
          expect(page).to have_content('15000€')
          expect(page).to have_content('Vérification KYC requise')
        end
      end
    end
    
    context 'Environmental compliance' do
      let(:document) do
        create(:document,
          space: space,
          uploaded_by: user,
          title: 'Rapport de projet construction',
          ai_category: 'report',
          tags: [create(:tag, name: 'environmental')],
          extracted_text: 'Projet de construction d\'un bâtiment de 5000m²'
        )
      end
      
      it 'checks for environmental impact assessment' do
        login_as(user, scope: :user)
        visit ged_document_path(document)
        
        click_button 'Vérifier la conformité'
        
        within '.compliance-results' do
          expect(page).to have_content('Conformité environnementale')
          expect(page).to have_content('Aucune évaluation d\'impact environnemental')
          expect(page).to have_content('Aucun plan de gestion des déchets')
        end
      end
    end
  end
  
  describe 'Compliance Dashboard' do
    let!(:compliant_docs) do
      2.times.map do
        doc = create(:document, space: space, uploaded_by: user, ai_category: 'report')
        doc.tags << create(:tag, name: 'compliance:compliant')
        doc
      end
    end
    
    let!(:non_compliant_docs) do
      3.times.map do
        doc = create(:document, space: space, uploaded_by: user, ai_category: 'contract')
        doc.tags << create(:tag, name: 'compliance:non-compliant')
        doc.tags << create(:tag, name: 'compliance:high-risk')
        doc
      end
    end
    
    it 'shows compliance overview' do
      login_as(user, scope: :user)
      visit ged_space_path(space)
      
      click_link 'Tableau de bord conformité'
      
      within '.compliance-dashboard' do
        expect(page).to have_content('Vue d\'ensemble de la conformité')
        
        # Statistics
        expect(page).to have_content('Documents conformes: 2')
        expect(page).to have_content('Documents non conformes: 3')
        expect(page).to have_content('Score moyen: ')
        
        # Risk distribution
        within '.risk-distribution' do
          expect(page).to have_content('Risque élevé: 3')
          expect(page).to have_content('Risque moyen: 0')
          expect(page).to have_content('Risque faible: 0')
        end
        
        # Filter by compliance status
        select 'Non conforme', from: 'compliance_status'
        click_button 'Filtrer'
        
        expect(page).to have_css('.document-row', count: 3)
      end
    end
  end
  
  describe 'Compliance Integration with Validation' do
    let(:document) do
      create(:document,
        space: space,
        uploaded_by: user,
        ai_category: 'contract',
        extracted_text: 'Contrat sans clauses RGPD'
      )
    end
    
    it 'shows compliance warnings during validation' do
      # Run compliance check
      RegulatoryComplianceService.check_document_compliance(document)
      
      validator = create(:user, organization: organization)
      space.authorize_user(validator, 'validate', granted_by: admin)
      
      validation_request = document.request_validation(
        requester: user,
        validators: [validator],
        min_validations: 1
      )
      
      login_as(validator, scope: :user)
      visit ged_document_validation_path(document, validation_request)
      
      # Should see compliance warnings
      within '.compliance-warnings' do
        expect(page).to have_content('Avertissements de conformité')
        expect(page).to have_content('Ce document présente des problèmes de conformité')
        expect(page).to have_content('GDPR/RGPD')
      end
      
      # Can still validate but with warning
      expect(page).to have_button('Approuver malgré les avertissements')
    end
  end
  
  describe 'Batch Compliance Operations' do
    let!(:documents) do
      5.times.map do |i|
        create(:document,
          space: space,
          uploaded_by: user,
          title: "Document #{i + 1}",
          ai_category: ['contract', 'invoice', 'report'].sample
        )
      end
    end
    
    it 'generates compliance report for multiple documents' do
      login_as(user, scope: :user)
      visit ged_space_path(space)
      
      # Select all documents
      check 'select_all_documents'
      
      click_button 'Actions groupées'
      click_link 'Rapport de conformité'
      
      within '#compliance-report-modal' do
        click_button 'Générer le rapport'
      end
      
      expect(page).to have_content('Rapport de conformité')
      expect(page).to have_content('Documents analysés: 5')
      expect(page).to have_content('Taux de conformité global:')
      
      # Download report
      click_link 'Télécharger le rapport (PDF)'
      
      # Check CSV export
      click_link 'Exporter les détails (CSV)'
    end
  end
end