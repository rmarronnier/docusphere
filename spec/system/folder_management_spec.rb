require 'rails_helper'

RSpec.describe "Folder Management", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  let!(:root_folder) { create(:folder, name: "Documents", space: space, parent: nil) }
  
  before do
    login_as(user, scope: :user)
  end
  
  describe "folder navigation and creation", js: true do
    it "allows user to navigate through folders and create subfolders" do
      # 1. Aller à l'espace
      visit ged_space_path(space)
      expect(page).to have_content(space.name)
      expect(page).to have_content("Documents")
      
      # 2. Cliquer sur le dossier racine
      click_link "Documents"
      expect(page).to have_current_path(ged_folder_path(root_folder))
      
      # 3. Créer un nouveau sous-dossier
      click_button "Nouveau dossier"
      
      # Attendre la modale
      expect(page).to have_css('#createFolderModal:not(.hidden)', wait: 2)
      
      within '#createFolderModal' do
        fill_in "folder_name", with: "Contrats 2024"
        fill_in "folder_description", with: "Tous les contrats de l'année 2024"
        
        click_button "Créer"
      end
      
      # 4. Vérifier la création
      expect(page).to have_content("Dossier créé avec succès")
      expect(page).to have_content("Contrats 2024")
      
      # 5. Naviguer dans le nouveau dossier
      click_link "Contrats 2024"
      
      expect(page).to have_content("Contrats 2024")
      expect(page).to have_content("Tous les contrats de l'année 2024")
      
      # 6. Vérifier le fil d'Ariane
      within '.breadcrumb' do
        expect(page).to have_link(space.name)
        expect(page).to have_link("Documents")
        expect(page).to have_content("Contrats 2024")
      end
      
      # 7. Retourner au dossier parent via le fil d'Ariane
      within '.breadcrumb' do
        click_link "Documents"
      end
      
      expect(page).to have_current_path(ged_folder_path(root_folder))
    end
    
    it "handles folder permissions correctly" do
      subfolder = create(:folder, name: "Privé", space: space, parent: root_folder)
      
      # Créer un autre utilisateur dans la même organisation
      other_user = create(:user, organization: organization)
      
      visit ged_folder_path(subfolder)
      
      # Définir les permissions
      click_button "Gérer les permissions"
      
      within '#permissionsModal' do
        # Retirer l'accès à other_user
        uncheck "user_#{other_user.id}_read"
        click_button "Enregistrer"
      end
      
      expect(page).to have_content("Permissions mises à jour")
      
      # Se connecter en tant qu'autre utilisateur
      logout(:user)
      login_as(other_user, scope: :user)
      
      # Essayer d'accéder au dossier
      visit ged_folder_path(subfolder)
      
      expect(page).to have_content("Vous n'avez pas accès à ce dossier")
      expect(page).to have_current_path(ged_dashboard_path)
    end
  end
  
  describe "folder operations", js: true do
    let!(:folder) { create(:folder, name: "À renommer", space: space, parent: root_folder) }
    let!(:document) { create(:document, title: "Doc test", folder: folder, space: space) }
    
    it "allows renaming folders" do
      visit ged_folder_path(folder)
      
      # Ouvrir le menu contextuel
      find('[data-action="click->dropdown#toggle"]').click
      
      within '[data-dropdown-target="menu"]' do
        click_link "Renommer"
      end
      
      # Renommer dans la modale
      within '#renameFolderModal' do
        fill_in "folder_name", with: "Contrats finalisés"
        click_button "Renommer"
      end
      
      expect(page).to have_content("Dossier renommé avec succès")
      expect(page).to have_content("Contrats finalisés")
      expect(page).not_to have_content("À renommer")
    end
    
    it "allows moving folders" do
      target_folder = create(:folder, name: "Archives", space: space, parent: root_folder)
      
      visit ged_folder_path(folder)
      
      find('[data-action="click->dropdown#toggle"]').click
      
      within '[data-dropdown-target="menu"]' do
        click_link "Déplacer"
      end
      
      within '#moveFolderModal' do
        select "Archives", from: "parent_folder_id"
        click_button "Déplacer"
      end
      
      expect(page).to have_content("Dossier déplacé avec succès")
      
      # Vérifier le nouveau chemin
      within '.breadcrumb' do
        expect(page).to have_link("Archives")
      end
    end
    
    it "prevents deletion of non-empty folders" do
      visit ged_folder_path(folder)
      
      find('[data-action="click->dropdown#toggle"]').click
      
      within '[data-dropdown-target="menu"]' do
        click_link "Supprimer"
      end
      
      # Confirmer la suppression
      page.accept_confirm
      
      expect(page).to have_content("Ce dossier contient des documents et ne peut pas être supprimé")
      expect(page).to have_content(folder.name)
    end
    
    it "allows deletion of empty folders" do
      empty_folder = create(:folder, name: "À supprimer", space: space, parent: root_folder)
      
      visit ged_folder_path(empty_folder)
      
      find('[data-action="click->dropdown#toggle"]').click
      
      within '[data-dropdown-target="menu"]' do
        click_link "Supprimer"
      end
      
      # Confirmer la suppression
      page.accept_confirm
      
      expect(page).to have_content("Dossier supprimé avec succès")
      expect(page).to have_current_path(ged_folder_path(root_folder))
      expect(page).not_to have_content("À supprimer")
    end
  end
  
  describe "bulk operations", js: true do
    let!(:folder1) { create(:folder, name: "Dossier 1", space: space, parent: root_folder) }
    let!(:folder2) { create(:folder, name: "Dossier 2", space: space, parent: root_folder) }
    let!(:doc1) { create(:document, title: "Document 1", folder: root_folder, space: space) }
    let!(:doc2) { create(:document, title: "Document 2", folder: root_folder, space: space) }
    
    it "allows selecting and moving multiple items" do
      visit ged_folder_path(root_folder)
      
      # Activer le mode sélection
      click_button "Sélection multiple"
      
      # Sélectionner des éléments
      within "#folder_#{folder1.id}" do
        check "select_folder_#{folder1.id}"
      end
      
      within "#document_#{doc1.id}" do
        check "select_document_#{doc1.id}"
      end
      
      # La barre d'actions doit apparaître
      expect(page).to have_css('.bulk-actions-bar')
      within '.bulk-actions-bar' do
        expect(page).to have_content("2 éléments sélectionnés")
      end
      
      # Déplacer les éléments
      within '.bulk-actions-bar' do
        click_button "Déplacer"
      end
      
      within '#bulkMoveModal' do
        select "Dossier 2", from: "target_folder_id"
        click_button "Déplacer les éléments"
      end
      
      expect(page).to have_content("2 éléments déplacés avec succès")
      
      # Vérifier que les éléments ne sont plus dans le dossier actuel
      expect(page).not_to have_content("Dossier 1")
      expect(page).not_to have_content("Document 1")
      expect(page).to have_content("Dossier 2")
      expect(page).to have_content("Document 2")
    end
    
    it "allows bulk deletion with confirmation" do
      visit ged_folder_path(root_folder)
      
      click_button "Sélection multiple"
      
      # Sélectionner uniquement des documents
      check "select_document_#{doc1.id}"
      check "select_document_#{doc2.id}"
      
      within '.bulk-actions-bar' do
        click_button "Supprimer"
      end
      
      # Modale de confirmation
      within '#bulkDeleteModal' do
        expect(page).to have_content("Êtes-vous sûr de vouloir supprimer 2 éléments ?")
        expect(page).to have_content("Document 1")
        expect(page).to have_content("Document 2")
        
        click_button "Confirmer la suppression"
      end
      
      expect(page).to have_content("2 éléments supprimés avec succès")
      expect(page).not_to have_content("Document 1")
      expect(page).not_to have_content("Document 2")
    end
  end
  
  describe "folder tree view", js: true do
    let!(:parent) { create(:folder, name: "Parent", space: space, parent: root_folder) }
    let!(:child1) { create(:folder, name: "Enfant 1", space: space, parent: parent) }
    let!(:child2) { create(:folder, name: "Enfant 2", space: space, parent: parent) }
    let!(:grandchild) { create(:folder, name: "Petit-enfant", space: space, parent: child1) }
    
    it "displays folder hierarchy in tree view" do
      visit ged_space_path(space)
      
      # Basculer vers la vue arborescente
      click_button "Vue arborescente"
      
      within '.folder-tree' do
        # Le dossier racine doit être visible
        expect(page).to have_content("Documents")
        
        # Développer le dossier racine
        within "#tree_folder_#{root_folder.id}" do
          find('.tree-toggle').click
        end
        
        # Le parent doit être visible
        expect(page).to have_content("Parent")
        
        # Développer le parent
        within "#tree_folder_#{parent.id}" do
          find('.tree-toggle').click
        end
        
        # Les enfants doivent être visibles
        expect(page).to have_content("Enfant 1")
        expect(page).to have_content("Enfant 2")
        
        # Développer Enfant 1
        within "#tree_folder_#{child1.id}" do
          find('.tree-toggle').click
        end
        
        # Le petit-enfant doit être visible
        expect(page).to have_content("Petit-enfant")
      end
      
      # Naviguer en cliquant sur un dossier dans l'arbre
      within '.folder-tree' do
        click_link "Enfant 2"
      end
      
      expect(page).to have_current_path(ged_folder_path(child2))
      expect(page).to have_content("Enfant 2")
    end
  end
end