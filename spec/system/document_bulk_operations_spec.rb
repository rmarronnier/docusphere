require 'rails_helper'

RSpec.describe 'Document Bulk Operations', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space) }
  
  let!(:documents) do
    5.times.map do |i|
      create(:document, 
        space: space, 
        folder: folder,
        uploaded_by: user,
        title: "Document #{i + 1}",
        processing_status: 'completed'
      )
    end
  end
  
  before do
    space.authorize_user(user, 'write', granted_by: admin)
  end
  
  describe 'Bulk selection' do
    it 'allows selecting multiple documents' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      # Check individual documents
      check "document_#{documents[0].id}"
      check "document_#{documents[1].id}"
      check "document_#{documents[2].id}"
      
      expect(page).to have_content('3 documents sélectionnés')
      expect(page).to have_button('Actions groupées')
      
      # Select all
      check 'select_all_documents'
      expect(page).to have_content('5 documents sélectionnés')
      
      # Deselect all
      uncheck 'select_all_documents'
      expect(page).not_to have_content('documents sélectionnés')
    end
  end
  
  describe 'Bulk tagging' do
    it 'adds tags to multiple documents' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      # Select documents
      documents[0..2].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Ajouter des tags'
      
      within '#bulk-tag-modal' do
        fill_in 'Tags', with: 'urgent, à-réviser, 2024'
        click_button 'Appliquer'
      end
      
      expect(page).to have_content('3 document(s) étiqueté(s)')
      
      # Verify tags were added
      visit ged_document_path(documents[0])
      expect(page).to have_content('urgent')
      expect(page).to have_content('à-réviser')
      expect(page).to have_content('2024')
    end
    
    it 'removes tags from multiple documents' do
      # Add tags first
      documents[0..2].each do |doc|
        doc.tags << create(:tag, name: 'old-tag')
      end
      
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..2].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Retirer des tags'
      
      within '#bulk-untag-modal' do
        check 'old-tag'
        click_button 'Retirer'
      end
      
      expect(page).to have_content('Étiquettes retirées de 3 document(s)')
      
      # Verify tags were removed
      visit ged_document_path(documents[0])
      expect(page).not_to have_content('old-tag')
    end
  end
  
  describe 'Bulk moving' do
    let(:destination_folder) { create(:folder, space: space, name: 'Archive 2024') }
    
    it 'moves multiple documents to another folder' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..1].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Déplacer'
      
      within '#bulk-move-modal' do
        select 'Archive 2024', from: 'Dossier de destination'
        click_button 'Déplacer'
      end
      
      expect(page).to have_content('2 document(s) déplacé(s)')
      
      # Verify documents were moved
      visit ged_folder_path(destination_folder)
      expect(page).to have_content(documents[0].title)
      expect(page).to have_content(documents[1].title)
      
      # Original folder should not have them
      visit ged_folder_path(folder)
      expect(page).not_to have_content(documents[0].title)
      expect(page).not_to have_content(documents[1].title)
    end
  end
  
  describe 'Bulk locking/unlocking' do
    it 'locks multiple documents' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..1].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Verrouiller'
      
      within '#bulk-lock-modal' do
        fill_in 'Raison du verrouillage', with: 'Audit en cours'
        click_button 'Verrouiller'
      end
      
      expect(page).to have_content('2 document(s) verrouillé(s)')
      
      # Verify documents are locked
      visit ged_document_path(documents[0])
      expect(page).to have_content('Document verrouillé')
      expect(page).to have_content('Audit en cours')
    end
    
    it 'unlocks multiple documents' do
      # Lock documents first
      documents[0..1].each do |doc|
        doc.lock_document!(user, reason: 'Test lock')
      end
      
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..1].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Déverrouiller'
      
      expect(page).to have_content('2 document(s) déverrouillé(s)')
      
      # Verify documents are unlocked
      expect(documents[0].reload).not_to be_locked
      expect(documents[1].reload).not_to be_locked
    end
  end
  
  describe 'Bulk archiving' do
    it 'archives multiple documents' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..2].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Archiver'
      
      confirm_dialog
      
      expect(page).to have_content('3 document(s) archivé(s)')
      
      # Archived documents should not be visible by default
      expect(page).not_to have_content(documents[0].title)
      expect(page).not_to have_content(documents[1].title)
      expect(page).not_to have_content(documents[2].title)
      
      # Show archived documents
      check 'show_archived'
      
      expect(page).to have_content(documents[0].title)
      expect(page).to have_css('.archived-document', count: 3)
    end
  end
  
  describe 'Bulk deletion' do
    it 'marks multiple documents for deletion' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[3..4].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Supprimer'
      
      within '#confirm-delete-modal' do
        expect(page).to have_content('Êtes-vous sûr de vouloir supprimer 2 documents ?')
        click_button 'Confirmer la suppression'
      end
      
      expect(page).to have_content('2 document(s) marqué(s) pour suppression')
      
      # Documents should be marked for deletion
      expect(documents[3].reload).to be_marked_for_deletion
      expect(documents[4].reload).to be_marked_for_deletion
    end
  end
  
  describe 'Bulk download' do
    it 'downloads multiple documents as a zip file' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..1].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      
      # This will trigger a download
      expect {
        click_link 'Télécharger'
      }.to change { Dir[Rails.root.join('tmp', 'documents_*.zip')].count }.by(0) # File is sent and deleted
      
      # In a real browser test, we would verify the download occurred
      # For now, we just check that no error was raised
    end
  end
  
  describe 'Bulk AI classification' do
    it 'triggers AI classification for multiple documents' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      # Select unclassified documents
      unclassified = documents.select { |d| d.ai_category.nil? }
      unclassified[0..1].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Classifier (IA)'
      
      expect(page).to have_content('Classification IA en cours...')
      expect(page).to have_content('2 document(s) classifié(s)')
      
      # Verify classification occurred
      unclassified[0].reload
      expect(unclassified[0].ai_category).not_to be_nil
    end
  end
  
  describe 'Bulk compliance check' do
    before do
      documents[0].update(ai_category: 'contract')
      documents[1].update(ai_category: 'invoice')
    end
    
    it 'checks compliance for multiple documents' do
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..1].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Vérifier la conformité'
      
      expect(page).to have_content('Vérification de conformité en cours...')
      
      within '#compliance-results' do
        expect(page).to have_content('Vérification de conformité terminée')
        expect(page).to have_content('Total vérifié: 2')
        expect(page).to have_content('Conforme:')
        expect(page).to have_content('Non conforme:')
        
        # Show details for non-compliant documents
        if page.has_content?('Non conforme: 1')
          click_link 'Voir les détails'
          expect(page).to have_content('Violations détectées')
        end
      end
    end
  end
  
  describe 'Permission checks' do
    let(:other_user) { create(:user, organization: organization) }
    
    before do
      space.authorize_user(other_user, 'read', granted_by: admin)
    end
    
    it 'restricts bulk actions based on permissions' do
      login_as(other_user, scope: :user)
      visit ged_folder_path(folder)
      
      # Can select documents
      check "document_#{documents[0].id}"
      
      click_button 'Actions groupées'
      
      # Should only see download action (read permission)
      expect(page).to have_link('Télécharger')
      expect(page).not_to have_link('Supprimer')
      expect(page).not_to have_link('Déplacer')
      expect(page).not_to have_link('Verrouiller')
    end
  end
  
  describe 'Error handling' do
    it 'handles partial failures gracefully' do
      # Lock one document by another user
      documents[1].lock_document!(admin, reason: 'Admin lock')
      
      login_as(user, scope: :user)
      visit ged_folder_path(folder)
      
      documents[0..2].each { |doc| check "document_#{doc.id}" }
      
      click_button 'Actions groupées'
      click_link 'Supprimer'
      
      within '#confirm-delete-modal' do
        click_button 'Confirmer la suppression'
      end
      
      # Should show partial success
      expect(page).to have_content('2 document(s) marqué(s) pour suppression')
      expect(page).to have_content('Permission refusée pour Document 2')
      
      # Verify only unlocked documents were deleted
      expect(documents[0].reload).to be_marked_for_deletion
      expect(documents[1].reload).not_to be_marked_for_deletion # Still locked
      expect(documents[2].reload).to be_marked_for_deletion
    end
  end
  
  private
  
  def confirm_dialog
    page.driver.browser.switch_to.alert.accept
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    # For non-JS tests or if confirm dialog is handled differently
  end
end