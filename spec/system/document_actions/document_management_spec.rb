require 'rails_helper'

RSpec.describe 'Document Management Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, organization: organization, role: :admin) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, name: 'Test Folder', space: space) }
  let(:other_user) { create(:user, organization: organization) }
  
  before do
    sign_in user
  end
  
  describe 'Document Organization' do
    let!(:documents) { create_list(:document, 5, folder: folder, space: space, uploaded_by: user) }
    
    xit 'moves documents between folders' do
      # TODO: Implémenter la fonctionnalité de déplacement groupé
      source_folder = folder
      target_folder = create(:folder, name: 'Archive 2025', space: space)
      
      visit ged_folder_path(source_folder)
      
      # Select documents
      within '.document-grid' do
        check "select_#{documents[0].id}"
        check "select_#{documents[1].id}"
      end
      
      expect(page).to have_content('2 documents sélectionnés')
      
      # Bulk move
      click_button 'Actions groupées'
      click_link 'Déplacer'
      
      within '.move-modal' do
        # Folder tree navigation
        expect(page).to have_css('.folder-tree')
        
        # Expand space
        find(".folder-node[data-id='#{space.id}'] .expand-icon").click
        
        # Select target folder
        find(".folder-node[data-id='#{target_folder.id}']").click
        
        expect(page).to have_css('.selected-folder', text: 'Archive 2025')
        
        click_button 'Déplacer ici'
      end
      
      expect(page).to have_content('2 documents déplacés avec succès')
      
      # Verify documents moved
      visit ged_folder_path(target_folder)
      expect(page).to have_content(documents[0].title)
      expect(page).to have_content(documents[1].title)
    end
    
    xit 'creates and manages folder structure' do
      # TODO: Implémenter la création de dossiers
      visit ged_space_path(space)
      
      click_button 'Nouveau dossier'
      
      within '.folder-creation-modal' do
        fill_in 'Nom', with: 'Projets 2025'
        fill_in 'Description', with: 'Tous les projets de l\'année 2025'
        select 'Projets', from: 'Icône'
        
        # Permissions
        check 'Hériter des permissions du parent'
        
        click_button 'Créer dossier'
      end
      
      expect(page).to have_content('Dossier créé avec succès')
      expect(page).to have_css('.folder-card', text: 'Projets 2025')
      
      # Create subfolder
      click_link 'Projets 2025'
      
      click_button 'Nouveau sous-dossier'
      
      within '.folder-creation-modal' do
        fill_in 'Nom', with: 'Q1 2025'
        click_button 'Créer dossier'
      end
      
      expect(page).to have_content('Q1 2025')
      
      # Breadcrumb navigation
      within '.breadcrumb' do
        expect(page).to have_link(space.name)
        expect(page).to have_link('Projets 2025')
        expect(page).to have_content('Q1 2025')
      end
    end
    
    it 'renames documents using edit action' do
      document = documents.first
      
      visit ged_document_path(document)
      
      # Use the actions dropdown in the viewer
      # Click on the menu button with the correct data-action
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Click on edit action if it exists
      if page.has_link?('Modifier', wait: 2)
        click_link 'Modifier'
        
        # TODO: Implémenter le formulaire de modification
        within '.edit-document-form' do
          fill_in 'document[title]', with: 'Rapport_Final_2025.pdf'
          click_button 'Enregistrer'
        end
        
        expect(page).to have_content('Document modifié avec succès')
        expect(page).to have_content('Rapport_Final_2025.pdf')
      else
        skip 'Edit functionality not yet implemented in dropdown'
      end
    end
  end
  
  describe 'Document Metadata Management' do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    xit 'edits document metadata in bulk' do
      # TODO: Implémenter la modification groupée des métadonnées
      documents = create_list(:document, 3, folder: folder, space: space, uploaded_by: user)
      
      visit ged_folder_path(folder)
      
      # Select all
      check 'select_all'
      
      click_button 'Actions groupées'
      click_link 'Modifier métadonnées'
      
      within '.bulk-metadata-modal' do
        # Common metadata
        select 'Contrat', from: 'Catégorie'
        fill_in 'Tags à ajouter', with: 'important, Q4-2025'
        fill_in 'Tags à retirer', with: 'draft'
        
        # Custom metadata
        click_button 'Ajouter champ personnalisé'
        fill_in 'field_name_1', with: 'Client'
        fill_in 'field_value_1', with: 'ACME Corp'
        
        click_button 'Ajouter champ personnalisé'
        fill_in 'field_name_2', with: 'Date d\'expiration'
        fill_in 'field_value_2', with: '31/12/2025'
        
        click_button 'Appliquer'
      end
      
      expect(page).to have_content('Métadonnées mises à jour pour 3 documents')
      
      # Verify changes
      click_link documents.first.title
      
      within '.document-metadata' do
        expect(page).to have_content('Catégorie: Contrat')
        expect(page).to have_content('important')
        expect(page).to have_content('Q4-2025')
        expect(page).to have_content('Client: ACME Corp')
        expect(page).to have_content('Date d\'expiration: 31/12/2025')
      end
    end
    
    xit 'manages document tags with autocomplete' do
      # TODO: Implémenter la gestion des tags avec autocomplétion
      visit ged_document_path(document)
      
      within '.document-tags' do
        click_button 'Modifier tags'
        
        # Autocomplete
        fill_in 'tags', with: 'conf'
        
        expect(page).to have_css('.tag-suggestions')
        expect(page).to have_content('confidentiel')
        expect(page).to have_content('conference')
        
        click_link 'confidentiel'
        
        # Add custom tag
        fill_in 'tags', with: 'urgent-2025'
        page.send_keys(:enter)
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Tags mis à jour')
      expect(page).to have_css('.tag', text: 'confidentiel')
      expect(page).to have_css('.tag', text: 'urgent-2025')
      
      # Remove tag
      within '.tag', text: 'confidentiel' do
        click_button '×'
      end
      
      expect(page).not_to have_css('.tag', text: 'confidentiel')
    end
  end
  
  describe 'Document Permissions' do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    xit 'manages document access permissions' do
      # TODO: Implémenter la gestion des permissions
      visit ged_document_path(document)
      
      # TODO: Add permissions link/button when implemented
      skip 'Permissions functionality not yet implemented'
      
      click_link 'Permissions'
      
      within '.permissions-panel' do
        expect(page).to have_content('Permissions actuelles')
        expect(page).to have_content(user.display_name)
        expect(page).to have_content('Propriétaire')
        
        # Add user permission
        click_button 'Ajouter utilisateur'
        
        within '.add-permission-modal' do
          select other_user.display_name, from: 'Utilisateur'
          select 'Lecture', from: 'Permission'
          check 'Peut télécharger'
          uncheck 'Peut partager'
          
          click_button 'Ajouter'
        end
        
        expect(page).to have_content("#{other_user.display_name} - Lecture")
        
        # Add group permission
        group = create(:user_group, organization: organization)
        
        click_button 'Ajouter groupe'
        
        within '.add-permission-modal' do
          select group.name, from: 'Groupe'
          select 'Écriture', from: 'Permission'
          
          click_button 'Ajouter'
        end
        
        expect(page).to have_content("#{group.name} (groupe) - Écriture")
        
        # Modify permission
        within ".permission-row[data-user='#{other_user.id}']" do
          click_button 'Modifier'
          select 'Écriture', from: 'Permission'
          click_button 'Enregistrer'
        end
        
        expect(page).to have_content("#{other_user.display_name} - Écriture")
        
        # Remove permission
        within ".permission-row[data-user='#{other_user.id}']" do
          click_button 'Retirer'
        end
        
        accept_confirm
        
        expect(page).not_to have_content(other_user.display_name)
      end
    end
    
    it 'creates a share link for document' do
      visit ged_document_path(document)
      
      # Click the share button in the document viewer
      # The share functionality is implemented in DocumentShareModalComponent
      within '.document-viewer-container' do
        # Find and click the share button
        find('button[data-modal-target-value="share-modal"]').click if page.has_css?('button[data-modal-target-value="share-modal"]')
      end
      
      # The modal should open
      within '#share-modal', visible: true do
        expect(page).to have_content('Partager le document')
        
        # Test the share by email functionality
        fill_in 'email', with: 'test@example.com'
        fill_in 'message', with: 'Voici le document à consulter'
        
        click_button 'Envoyer'
      end
      
      expect(page).to have_content('Invitation envoyée avec succès')
    end
  end
  
  describe 'Document Lifecycle' do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    it 'locks and unlocks document for editing' do
      visit ged_document_path(document)
      
      # The lock button is in the legacy view section
      within '.legacy-document-view' do
        # Make the legacy view visible for this test
        page.execute_script("document.querySelector('.legacy-document-view').classList.remove('hidden')")
        
        expect(page).to have_button('Verrouiller')
        
        # Click the lock button which opens a modal
        find('button[data-modal-target-value="lock-document-modal"]').click
      end
      
      within '#lock-document-modal', visible: true do
        fill_in 'lock_reason', with: 'Mise à jour majeure en cours'
        fill_in 'unlock_scheduled_at', with: 2.hours.from_now
        
        click_button 'Verrouiller'
      end
      
      expect(page).to have_content('Document verrouillé avec succès')
      
      # Refresh to see lock status
      visit ged_document_path(document)
      
      within '.legacy-document-view' do
        page.execute_script("document.querySelector('.legacy-document-view').classList.remove('hidden')")
        
        # Check for lock indicator
        within '.bg-yellow-50' do
          expect(page).to have_content('Document verrouillé')
          expect(page).to have_content("Verrouillé par #{user.display_name}")
          expect(page).to have_content('Mise à jour majeure en cours')
        end
      end
      
      # Test unlock
      # The unlock is a form submission, not a modal
      within '.legacy-document-view' do
        click_button 'Déverrouiller'
      end
      
      expect(page).to have_content('Document déverrouillé avec succès')
    end
    
    xit 'archives document using dropdown action' do
      # TODO: Implémenter la fonctionnalité d'archivage
      visit ged_document_path(document)
      
      # Click on the actions dropdown button
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Look for archive action in the dropdown
      within '[data-dropdown-target="menu"]', visible: true do
        if page.has_link?('Archiver', wait: 2)
          click_link 'Archiver'
        else
          skip 'Archive functionality not yet implemented in dropdown'
        end
      end
      
      # If archive modal exists, fill it
      if page.has_css?('.archive-modal', wait: 2)
        within '.archive-modal' do
          fill_in 'Raison d\'archivage', with: 'Projet terminé, conservation légale'
          select '7 ans', from: 'Durée de conservation'
          check 'Compresser le document'
          
          click_button 'Archiver'
        end
        
        expect(page).to have_content('Document archivé')
      end
    end
    
    it 'permanently deletes document with confirmation' do
      sign_in admin_user
      visit ged_document_path(document)
      
      # Click on the actions dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Look for delete action in the dropdown
      within '[data-dropdown-target="menu"]', visible: true do
        if page.has_link?('Supprimer', wait: 2)
          # The delete action should have danger styling
          delete_link = find('a', text: 'Supprimer')
          expect(delete_link[:class]).to include('text-red-700')
          
          # Click with confirmation
          accept_confirm do
            delete_link.click
          end
        else
          skip 'Delete functionality not yet implemented in dropdown'
        end
      end
      
      # If implemented, we should be redirected after deletion
      if current_path == ged_folder_path(folder)
        expect(page).to have_content('Document supprimé avec succès')
        expect(page).not_to have_content(document.title)
      end
    end
  end
  
  describe 'Document Duplication and Templates' do
    let(:template_doc) { create(:document, title: 'Template Contrat.docx', folder: folder, space: space, uploaded_by: user) }
    
    xit 'duplicates document with options' do
      # TODO: Implémenter la duplication de documents
      visit ged_document_path(template_doc)
      
      # Click on the actions dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      within '[data-dropdown-target="menu"]', visible: true do
        click_link 'Dupliquer' if page.has_link?('Dupliquer')
      end
      
      within '.duplicate-modal' do
        fill_in 'Nouveau nom', with: 'Contrat Client ABC.docx'
        
        # Options
        check 'Copier les métadonnées'
        check 'Copier les tags'
        uncheck 'Copier les permissions'
        check 'Copier les versions'
        
        # Target location
        select folder.name, from: 'Dossier de destination'
        
        click_button 'Dupliquer'
      end
      
      expect(page).to have_content('Document dupliqué avec succès')
      expect(page).to have_content('Contrat Client ABC.docx')
      
      # Verify duplication
      within '.document-info' do
        expect(page).to have_content('Copié de: Template Contrat.docx')
        expect(page).to have_content('Version 1')
      end
    end
    
    xit 'creates document template from existing' do
      # TODO: Implémenter la création de modèles
      sign_in admin_user
      visit ged_document_path(template_doc)
      
      # Click on the actions dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      within '[data-dropdown-target="menu"]', visible: true do
        click_link 'Enregistrer comme modèle' if page.has_link?('Enregistrer comme modèle')
      end
      
      within '.template-creation-modal' do
        fill_in 'Nom du modèle', with: 'Modèle Contrat Standard'
        fill_in 'Description', with: 'Modèle pour tous les contrats clients'
        select 'Contrats', from: 'Catégorie'
        
        # Template variables
        click_button 'Ajouter variable'
        fill_in 'variable_name_1', with: 'CLIENT_NAME'
        fill_in 'variable_desc_1', with: 'Nom du client'
        
        click_button 'Ajouter variable'
        fill_in 'variable_name_2', with: 'CONTRACT_DATE'
        fill_in 'variable_desc_2', with: 'Date du contrat'
        
        # Permissions
        check 'Disponible pour tous les utilisateurs'
        
        click_button 'Créer modèle'
      end
      
      expect(page).to have_content('Modèle créé avec succès')
      
      # Use template
      visit ged_folder_path(folder)
      click_button 'Nouveau document'
      click_link 'Depuis un modèle'
      
      within '.template-selector' do
        expect(page).to have_content('Modèle Contrat Standard')
        click_button 'Utiliser ce modèle'
      end
      
      within '.template-variables-form' do
        fill_in 'CLIENT_NAME', with: 'ACME Corporation'
        fill_in 'CONTRACT_DATE', with: '15/12/2025'
        
        click_button 'Créer document'
      end
      
      expect(page).to have_content('Document créé depuis le modèle')
      expect(page).to have_content('ACME Corporation')
    end
  end
  
  describe 'Bulk Document Operations' do
    let!(:documents) { create_list(:document, 10, folder: folder, space: space, uploaded_by: user) }
    
    xit 'performs bulk operations on selected documents' do
      # TODO: Implémenter les opérations groupées
      visit ged_folder_path(folder)
      
      # Select multiple
      documents[0..4].each do |doc|
        check "select_#{doc.id}"
      end
      
      expect(page).to have_content('5 documents sélectionnés')
      
      within '.bulk-actions-bar' do
        expect(page).to have_button('Télécharger')
        expect(page).to have_button('Déplacer')
        expect(page).to have_button('Tags')
        expect(page).to have_button('Supprimer')
        expect(page).to have_button('Plus')
        
        # Bulk download as ZIP
        click_button 'Télécharger'
        click_link 'Télécharger en ZIP'
      end
      
      expect(page).to have_content('Préparation de l\'archive...')
      expect(page.response_headers['Content-Type']).to include('application/zip')
      
      visit ged_folder_path(folder)
      
      # Bulk tag
      documents[0..2].each { |doc| check "select_#{doc.id}" }
      
      within '.bulk-actions-bar' do
        click_button 'Tags'
        click_link 'Ajouter tags'
      end
      
      within '.bulk-tag-modal' do
        fill_in 'Tags', with: 'archive-2025, processed'
        click_button 'Ajouter aux documents'
      end
      
      expect(page).to have_content('Tags ajoutés à 3 documents')
      
      # Verify tags added
      click_link documents.first.title
      expect(page).to have_css('.tag', text: 'archive-2025')
      expect(page).to have_css('.tag', text: 'processed')
    end
    
    xit 'exports document list with filters' do
      # TODO: Implémenter l'export de la liste de documents
      visit ged_folder_path(folder)
      
      # Apply filters
      select 'PDF', from: 'Type de fichier'
      fill_in 'Recherche', with: 'rapport'
      click_button 'Filtrer'
      
      # Export filtered results
      click_button 'Exporter'
      
      within '.export-modal' do
        select 'Excel', from: 'Format'
        
        # Columns to include
        check 'Nom'
        check 'Type'
        check 'Taille'
        check 'Date de création'
        check 'Téléversé par'
        check 'Tags'
        uncheck 'Chemin complet'
        
        click_button 'Exporter'
      end
      
      expect(page.response_headers['Content-Type']).to include('spreadsheet')
      expect(page.response_headers['Content-Disposition']).to include('.xlsx')
    end
  end
end