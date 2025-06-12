require 'rails_helper'

RSpec.describe 'Document Management Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, organization: organization, role: :admin) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, name: 'Test Folder', space: space) }
  
  before do
    sign_in user
  end
  
  describe 'Document Organization' do
    let!(:documents) { create_list(:document, 5, folder: folder, space: space, uploaded_by: user) }
    
    it 'moves documents between folders' do
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
    
    it 'creates and manages folder structure' do
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
    
    it 'renames documents and folders' do
      document = documents.first
      
      visit ged_folder_path(folder)
      
      within "#document_#{document.id}" do
        click_button 'Actions'
        click_link 'Renommer'
      end
      
      within '.rename-modal' do
        expect(find_field('Nom').value).to eq(document.title)
        
        fill_in 'Nom', with: 'Rapport_Final_2025.pdf'
        click_button 'Renommer'
      end
      
      expect(page).to have_content('Document renommé avec succès')
      expect(page).to have_content('Rapport_Final_2025.pdf')
      expect(page).not_to have_content(document.title)
    end
  end
  
  describe 'Document Metadata Management' do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    it 'edits document metadata in bulk' do
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
    
    it 'manages document tags with autocomplete' do
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
    let(:other_user) { create(:user, organization: organization) }
    
    it 'manages document access permissions' do
      visit ged_document_path(document)
      
      click_link 'Permissions'
      
      within '.permissions-panel' do
        expect(page).to have_content('Permissions actuelles')
        expect(page).to have_content(user.name)
        expect(page).to have_content('Propriétaire')
        
        # Add user permission
        click_button 'Ajouter utilisateur'
        
        within '.add-permission-modal' do
          select other_user.name, from: 'Utilisateur'
          select 'Lecture', from: 'Permission'
          check 'Peut télécharger'
          uncheck 'Peut partager'
          
          click_button 'Ajouter'
        end
        
        expect(page).to have_content("#{other_user.name} - Lecture")
        
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
        
        expect(page).to have_content("#{other_user.name} - Écriture")
        
        # Remove permission
        within ".permission-row[data-user='#{other_user.id}']" do
          click_button 'Retirer'
        end
        
        accept_confirm
        
        expect(page).not_to have_content(other_user.name)
      end
    end
    
    it 'sets document as public with expiration' do
      visit ged_document_path(document)
      
      click_button 'Partager'
      click_link 'Créer lien public'
      
      within '.public-link-modal' do
        check 'Activer le partage public'
        
        # Options
        check 'Lecture seule'
        uncheck 'Permettre le téléchargement'
        check 'Définir une expiration'
        fill_in 'Date d\'expiration', with: 7.days.from_now.to_date
        check 'Protéger par mot de passe'
        fill_in 'Mot de passe', with: 'SecurePass123!'
        
        click_button 'Générer lien'
      end
      
      expect(page).to have_content('Lien public créé')
      expect(page).to have_css('.public-link-info')
      
      within '.public-link-info' do
        expect(page).to have_content('Expire dans 7 jours')
        expect(page).to have_content('Protégé par mot de passe')
        expect(page).to have_button('Copier le lien')
        expect(page).to have_button('Envoyer par email')
        expect(page).to have_button('QR Code')
      end
      
      # Generate QR code
      click_button 'QR Code'
      
      within '.qr-code-modal' do
        expect(page).to have_css('.qr-code-image')
        expect(page).to have_button('Télécharger QR Code')
      end
    end
  end
  
  describe 'Document Lifecycle' do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    it 'locks and unlocks document for editing' do
      visit ged_document_path(document)
      
      expect(page).to have_button('Verrouiller')
      
      click_button 'Verrouiller'
      
      within '.lock-modal' do
        fill_in 'Raison', with: 'Mise à jour majeure en cours'
        check 'Notifier les utilisateurs concernés'
        
        click_button 'Verrouiller document'
      end
      
      expect(page).to have_content('Document verrouillé')
      expect(page).to have_css('.lock-indicator')
      expect(page).to have_content("Verrouillé par #{user.name}")
      expect(page).not_to have_button('Éditer')
      
      # Other users see lock
      sign_out user
      sign_in other_user
      
      visit ged_document_path(document)
      
      expect(page).to have_css('.lock-warning')
      expect(page).to have_content("Document verrouillé par #{user.name}")
      expect(page).to have_content('Mise à jour majeure en cours')
      expect(page).not_to have_button('Éditer')
      expect(page).not_to have_button('Nouvelle version')
      
      # Owner unlocks
      sign_out other_user
      sign_in user
      
      visit ged_document_path(document)
      
      click_button 'Déverrouiller'
      
      expect(page).to have_content('Document déverrouillé')
      expect(page).not_to have_css('.lock-indicator')
      expect(page).to have_button('Éditer')
    end
    
    it 'archives and restores documents' do
      visit ged_document_path(document)
      
      click_button 'Plus d\'actions'
      click_link 'Archiver'
      
      within '.archive-modal' do
        fill_in 'Raison d\'archivage', with: 'Projet terminé, conservation légale'
        select '7 ans', from: 'Durée de conservation'
        check 'Compresser le document'
        
        click_button 'Archiver'
      end
      
      expect(page).to have_content('Document archivé')
      expect(page).to have_css('.archived-badge')
      expect(page).not_to have_button('Éditer')
      expect(page).not_to have_button('Nouvelle version')
      
      # Search in archives
      visit ged_dashboard_path
      click_link 'Archives'
      
      expect(page).to have_content('Documents archivés')
      expect(page).to have_content(document.title)
      
      within "#document_#{document.id}" do
        expect(page).to have_content('Archivé il y a moins d\'une minute')
        expect(page).to have_content('Conservation: 7 ans')
        
        click_button 'Restaurer'
      end
      
      accept_confirm
      
      expect(page).to have_content('Document restauré')
      expect(page).not_to have_content(document.title) # Removed from archives view
      
      # Back in normal view
      visit ged_folder_path(folder)
      expect(page).to have_content(document.title)
      expect(page).not_to have_css('.archived-badge')
    end
    
    it 'permanently deletes document with confirmation' do
      sign_in admin_user
      visit ged_document_path(document)
      
      # Look for delete button in the viewer actions
      # The new interface doesn't have a "Plus d'actions" button
      # Instead, actions are displayed directly or through the viewer component
      
      # Try to find delete action - may be in a dropdown or as a direct button
      if page.has_button?('Supprimer')
        click_button 'Supprimer'
      elsif page.has_link?('Supprimer')
        click_link 'Supprimer'
      else
        # Try clicking on the actions menu icon if it exists
        find('[aria-label="Actions du document"]', visible: :all).click if page.has_css?('[aria-label="Actions du document"]')
        click_link 'Supprimer'
      end
      
      # Accept confirmation dialog
      accept_confirm do
        # The action should trigger a confirmation
      end
      
      expect(page).to have_content('Document supprimé')
      expect(current_path).to eq(ged_folder_path(folder))
      expect(page).not_to have_content(document.title)
    end
  end
  
  describe 'Document Duplication and Templates' do
    let(:template_doc) { create(:document, title: 'Template Contrat.docx', folder: folder, space: space, uploaded_by: user) }
    
    it 'duplicates document with options' do
      visit ged_document_path(template_doc)
      
      click_button 'Plus d\'actions'
      click_link 'Dupliquer'
      
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
    
    it 'creates document template from existing' do
      sign_in admin_user
      visit ged_document_path(template_doc)
      
      click_button 'Plus d\'actions'
      click_link 'Enregistrer comme modèle'
      
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
    
    it 'performs bulk operations on selected documents' do
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
    
    it 'exports document list with filters' do
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