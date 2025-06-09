require 'rails_helper'

RSpec.describe 'Document Validation System', type: :system do
  let(:organization) { create(:organization) }
  let(:requester) { create(:user, organization: organization) }
  let(:validator1) { create(:user, organization: organization) }
  let(:validator2) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  
  before do
    # Grant permissions
    space.authorize_user(requester, 'write', granted_by: admin)
    space.authorize_user(validator1, 'validate', granted_by: admin)
    space.authorize_user(validator2, 'validate', granted_by: admin)
  end
  
  describe 'Document upload and validation request' do
    it 'allows a user to upload a document and request validation' do
      login_as(requester, scope: :user)
      
      # Upload a document
      visit ged_space_path(space)
      click_button 'Nouveau document'
      
      within '#upload-document-modal' do
        fill_in 'Titre', with: 'Contrat de prestation'
        fill_in 'Description', with: 'Contrat pour services de consultation'
        attach_file 'document[file]', Rails.root.join('spec/fixtures/sample_document.pdf')
        click_button 'Uploader'
      end
      
      expect(page).to have_content('Document uploadé avec succès')
      document = Document.last
      
      # Navigate to document page
      visit ged_document_path(document)
      expect(page).to have_content('Contrat de prestation')
      expect(page).to have_button('Demander validation')
      
      # Request validation
      click_button 'Demander validation'
      
      within '#validation-request-modal' do
        check validator1.full_name
        check validator2.full_name
        fill_in 'Nombre minimum de validations', with: '1'
        click_button 'Envoyer la demande'
      end
      
      expect(page).to have_content('Demande de validation créée avec succès')
      expect(page).to have_content('Validation en cours')
      expect(document.reload.validation_pending?).to be true
    end
  end
  
  describe 'Validation workflow' do
    let(:document) { create(:document, space: space, uploaded_by: requester) }
    let!(:validation_request) do
      document.request_validation(
        requester: requester,
        validators: [validator1, validator2],
        min_validations: 1
      )
    end
    
    it 'allows validators to approve documents' do
      login_as(validator1, scope: :user)
      
      # Check pending validations
      visit ged_document_validations_path
      expect(page).to have_content('Validations en attente')
      expect(page).to have_content(document.title)
      
      # Navigate to validation page
      click_link document.title
      
      expect(page).to have_content('Demande de validation')
      expect(page).to have_content("Demandée par #{requester.full_name}")
      expect(page).to have_button('Approuver')
      expect(page).to have_button('Refuser')
      
      # Approve the document
      fill_in 'Commentaire', with: 'Document conforme aux exigences'
      click_button 'Approuver'
      
      expect(page).to have_content('Document approuvé avec succès')
      expect(validation_request.reload.status).to eq('approved')
    end
    
    it 'allows validators to reject documents' do
      login_as(validator2, scope: :user)
      
      visit ged_document_validation_path(document, validation_request)
      
      # Reject without comment should fail
      click_button 'Refuser'
      expect(page).to have_content('Un commentaire est requis')
      
      # Reject with comment
      fill_in 'Commentaire', with: 'Clauses manquantes dans le contrat'
      click_button 'Refuser'
      
      expect(page).to have_content('Document refusé')
      expect(validation_request.reload.status).to eq('rejected')
    end
    
    it 'shows validation progress to requester' do
      # First validator approves
      validation_request.document_validations.find_by(validator: validator1).approve!(comment: 'OK')
      
      login_as(requester, scope: :user)
      visit ged_document_path(document)
      
      expect(page).to have_content('Validation approuvée')
      expect(page).to have_content('1/2 validations complétées')
      
      # Check validation details
      click_link 'Voir les détails de validation'
      
      expect(page).to have_content(validator1.full_name)
      expect(page).to have_content('Approuvé')
      expect(page).to have_content(validator2.full_name)
      expect(page).to have_content('En attente')
    end
  end
  
  describe 'Bulk validation operations' do
    let!(:documents) do
      3.times.map { create(:document, space: space, uploaded_by: requester) }
    end
    
    it 'allows requesting validation for multiple documents' do
      login_as(requester, scope: :user)
      
      visit ged_space_path(space)
      
      # Select multiple documents
      documents.each do |doc|
        check "document_#{doc.id}"
      end
      
      # Open bulk actions menu
      click_button 'Actions groupées'
      click_link 'Demander validation'
      
      within '#bulk-validation-modal' do
        check validator1.full_name
        check validator2.full_name
        fill_in 'Nombre minimum de validations', with: '1'
        click_button 'Valider'
      end
      
      expect(page).to have_content('Validation demandée pour 3 document(s)')
      
      documents.each do |doc|
        expect(doc.reload.validation_pending?).to be true
      end
    end
  end
  
  describe 'Document locking during validation' do
    let(:document) { create(:document, space: space, uploaded_by: requester) }
    
    it 'prevents editing locked documents during validation' do
      # Lock document
      document.lock_document!(admin, reason: 'Validation en cours')
      
      login_as(requester, scope: :user)
      visit ged_document_path(document)
      
      expect(page).to have_content('Document verrouillé')
      expect(page).to have_content('Validation en cours')
      expect(page).not_to have_button('Modifier')
      expect(page).not_to have_button('Supprimer')
      
      # Admin can unlock
      login_as(admin, scope: :user)
      visit ged_document_path(document)
      
      click_button 'Déverrouiller'
      expect(page).to have_content('Document déverrouillé avec succès')
    end
  end
  
  describe 'AI classification integration' do
    let(:document) { create(:document, space: space, uploaded_by: requester, title: 'Facture N°2024-001') }
    
    it 'automatically classifies documents on upload', js: true do
      login_as(requester, scope: :user)
      
      visit ged_space_path(space)
      click_button 'Nouveau document'
      
      within '#upload-document-modal' do
        fill_in 'Titre', with: 'Facture N°2024-001'
        fill_in 'Description', with: 'Facture pour services de consultation. Montant TTC: 1500€'
        attach_file 'document[file]', Rails.root.join('spec/fixtures/sample_invoice.pdf')
        click_button 'Uploader'
      end
      
      # Wait for processing
      sleep 2
      
      document = Document.last
      visit ged_document_path(document)
      
      # Check AI classification
      expect(page).to have_content('Classification IA')
      expect(page).to have_content('Type: Facture')
      expect(page).to have_content('Confiance:')
      
      # Check auto-tags
      expect(page).to have_content('type:invoice')
      expect(page).to have_content('financial')
    end
  end
  
  describe 'Compliance checking' do
    let(:contract_document) do
      create(:document, 
        space: space, 
        uploaded_by: requester,
        title: 'Contrat de service',
        description: 'Contrat sans clause RGPD',
        ai_category: 'contract'
      )
    end
    
    it 'shows compliance warnings for non-compliant documents' do
      # Run compliance check
      RegulatoryComplianceService.check_document_compliance(contract_document)
      
      login_as(requester, scope: :user)
      visit ged_document_path(contract_document)
      
      expect(page).to have_content('Avertissements de conformité')
      expect(page).to have_content('GDPR/RGPD')
      expect(page).to have_content('Aucune mention de consentement')
      
      # Show remediation suggestions
      click_link 'Voir les recommandations'
      
      expect(page).to have_content('Ajouter une clause de consentement RGPD')
    end
  end
  
  describe 'Document versioning' do
    let(:document) { create(:document, space: space, uploaded_by: requester) }
    
    it 'allows creating and managing document versions' do
      login_as(requester, scope: :user)
      visit ged_document_path(document)
      
      # Upload new version
      click_button 'Nouvelle version'
      
      within '#new-version-modal' do
        attach_file 'file', Rails.root.join('spec/fixtures/sample_document_v2.pdf')
        fill_in 'Commentaire', with: 'Ajout des clauses RGPD'
        click_button 'Uploader'
      end
      
      expect(page).to have_content('Nouvelle version créée avec succès')
      
      # Check version history
      click_link 'Historique des versions'
      
      expect(page).to have_content('Version 2')
      expect(page).to have_content('Ajout des clauses RGPD')
      expect(page).to have_content('Version 1')
      
      # Restore previous version
      within '.version-1' do
        click_button 'Restaurer'
      end
      
      confirm_dialog
      
      expect(page).to have_content('Document restauré à partir de la version 1')
      expect(document.reload.current_version_number).to eq(3) # New version created from restore
    end
  end
  
  describe 'Validation notifications' do
    let(:document) { create(:document, space: space, uploaded_by: requester) }
    
    it 'sends notifications throughout the validation process' do
      # Request validation
      validation_request = document.request_validation(
        requester: requester,
        validators: [validator1],
        min_validations: 1
      )
      
      # Check validator received notification
      login_as(validator1, scope: :user)
      visit notifications_path
      
      expect(page).to have_content('Validation demandée')
      expect(page).to have_content(document.title)
      expect(page).to have_content(requester.full_name)
      
      # Approve document
      validation_request.document_validations.first.approve!(comment: 'Approuvé')
      
      # Check requester received notification
      login_as(requester, scope: :user)
      visit notifications_path
      
      expect(page).to have_content('Validation approuvée')
      expect(page).to have_content(document.title)
    end
  end
  
  private
  
  def confirm_dialog
    page.driver.browser.switch_to.alert.accept
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    # For non-JS tests or if confirm dialog is handled differently
  end
end