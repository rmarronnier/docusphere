require 'rails_helper'

RSpec.describe "Metadata and Tagging", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, 
    title: "Contrat Client ABC",
    space: space,
    user: user
  )}
  
  before do
    login_as(user, scope: :user)
  end
  
  describe "document tagging", js: true do
    let!(:existing_tag1) { create(:tag, name: "Urgent", organization: organization) }
    let!(:existing_tag2) { create(:tag, name: "Contrat", organization: organization) }
    
    it "adds and removes tags from document" do
      visit ged_document_path(document)
      
      # Ouvrir le panneau des tags
      click_button "Gérer les tags"
      
      within '#tagsPanel' do
        # Ajouter des tags existants
        fill_in "tag_search", with: "Urg"
        
        within '.tag-suggestions' do
          click_on "Urgent"
        end
        
        expect(page).to have_css('.selected-tag', text: "Urgent")
        
        # Ajouter un nouveau tag
        fill_in "tag_search", with: "Important"
        click_button "Créer le tag 'Important'"
        
        expect(page).to have_css('.selected-tag', text: "Important")
        
        # Ajouter par sélection dans la liste
        within '.popular-tags' do
          click_on "Contrat"
        end
        
        expect(page).to have_css('.selected-tag', text: "Contrat")
        
        # Enregistrer
        click_button "Enregistrer les tags"
      end
      
      expect(page).to have_content("Tags mis à jour")
      
      # Vérifier l'affichage des tags
      within '.document-tags' do
        expect(page).to have_content("Urgent")
        expect(page).to have_content("Important")
        expect(page).to have_content("Contrat")
      end
      
      # Retirer un tag
      click_button "Gérer les tags"
      
      within '#tagsPanel' do
        within '.selected-tag', text: "Urgent" do
          click_button "×"
        end
        
        click_button "Enregistrer les tags"
      end
      
      expect(page).not_to have_css('.document-tags', text: "Urgent")
    end
    
    it "suggests tags based on document content" do
      # Créer des tags utilisés fréquemment
      create(:tag, name: "Juridique", organization: organization, usage_count: 50)
      create(:tag, name: "Client", organization: organization, usage_count: 45)
      create(:tag, name: "2024", organization: organization, usage_count: 30)
      
      visit ged_document_path(document)
      click_button "Gérer les tags"
      
      within '#tagsPanel' do
        # Les suggestions automatiques basées sur le titre
        within '.suggested-tags' do
          expect(page).to have_content("Tags suggérés")
          expect(page).to have_button("Client") # Basé sur "Client ABC" dans le titre
          expect(page).to have_button("Contrat") # Basé sur "Contrat" dans le titre
          
          # Appliquer les suggestions
          click_button "Client"
          click_button "Contrat"
        end
        
        click_button "Enregistrer les tags"
      end
      
      expect(page).to have_css('.document-tags', text: "Client")
      expect(page).to have_css('.document-tags', text: "Contrat")
    end
    
    it "manages tag colors and categories" do
      visit ged_dashboard_path
      
      # Aller dans la gestion des tags
      click_link "Gérer les tags"
      
      # Créer une catégorie de tags
      click_button "Nouvelle catégorie"
      
      within '#newCategoryModal' do
        fill_in "category_name", with: "Statut"
        fill_in "category_color", with: "#FF5733"
        click_button "Créer"
      end
      
      # Créer des tags dans cette catégorie
      within '.tag-category', text: "Statut" do
        click_button "Ajouter un tag"
        
        fill_in "tag_name", with: "En cours"
        click_button "Créer"
        
        click_button "Ajouter un tag"
        fill_in "tag_name", with: "Terminé"
        click_button "Créer"
      end
      
      # Utiliser ces tags catégorisés
      visit ged_document_path(document)
      click_button "Gérer les tags"
      
      within '#tagsPanel' do
        # Les tags doivent être groupés par catégorie
        within '.tag-category-group', text: "Statut" do
          expect(page).to have_css('.tag-badge[style*="#FF5733"]', text: "En cours")
          expect(page).to have_css('.tag-badge[style*="#FF5733"]', text: "Terminé")
          
          click_on "En cours"
        end
        
        click_button "Enregistrer les tags"
      end
      
      # Le tag doit avoir la couleur de sa catégorie
      within '.document-tags' do
        expect(page).to have_css('.tag-badge[style*="#FF5733"]', text: "En cours")
      end
    end
  end
  
  describe "metadata management", js: true do
    let!(:metadata_template) { create(:metadata_template, 
      name: "Contrat Standard",
      organization: organization
    )}
    
    before do
      # Créer des champs de métadonnées
      metadata_template.metadata_fields.create!([
        { name: "client_name", label: "Nom du client", field_type: "string", required: true },
        { name: "contract_value", label: "Valeur du contrat", field_type: "number", required: true },
        { name: "start_date", label: "Date de début", field_type: "date", required: true },
        { name: "end_date", label: "Date de fin", field_type: "date", required: false },
        { name: "contract_type", label: "Type de contrat", field_type: "select", 
          options: ["Service", "Produit", "Maintenance"], required: true },
        { name: "auto_renewal", label: "Renouvellement automatique", field_type: "boolean", required: false }
      ])
    end
    
    it "applies metadata template to document" do
      visit ged_document_path(document)
      
      click_button "Gérer les métadonnées"
      
      within '#metadataModal' do
        # Sélectionner un modèle
        select "Contrat Standard", from: "metadata_template"
        
        # Les champs doivent apparaître
        expect(page).to have_field("Nom du client")
        expect(page).to have_field("Valeur du contrat")
        expect(page).to have_field("Date de début")
        
        # Remplir les métadonnées
        fill_in "Nom du client", with: "ABC Corporation"
        fill_in "Valeur du contrat", with: "50000"
        fill_in "Date de début", with: Date.today.strftime("%Y-%m-%d")
        fill_in "Date de fin", with: 1.year.from_now.strftime("%Y-%m-%d")
        select "Service", from: "Type de contrat"
        check "Renouvellement automatique"
        
        click_button "Enregistrer"
      end
      
      expect(page).to have_content("Métadonnées enregistrées")
      
      # Vérifier l'affichage
      within '.document-metadata' do
        expect(page).to have_content("Nom du client: ABC Corporation")
        expect(page).to have_content("Valeur du contrat: 50,000")
        expect(page).to have_content("Type de contrat: Service")
        expect(page).to have_content("Renouvellement automatique: Oui")
      end
    end
    
    it "validates required metadata fields" do
      visit ged_document_path(document)
      
      click_button "Gérer les métadonnées"
      
      within '#metadataModal' do
        select "Contrat Standard", from: "metadata_template"
        
        # Essayer de sauvegarder sans remplir les champs requis
        click_button "Enregistrer"
        
        # Vérifier les erreurs
        expect(page).to have_content("Nom du client est requis")
        expect(page).to have_content("Valeur du contrat est requis")
        expect(page).to have_content("Date de début est requis")
        expect(page).to have_content("Type de contrat est requis")
        
        # Les champs optionnels ne doivent pas avoir d'erreur
        expect(page).not_to have_content("Date de fin est requis")
      end
    end
    
    it "creates custom metadata fields" do
      visit ged_document_path(document)
      
      click_button "Gérer les métadonnées"
      
      within '#metadataModal' do
        # Passer en mode personnalisé
        click_link "Métadonnées personnalisées"
        
        # Ajouter des champs personnalisés
        click_button "Ajouter un champ"
        
        within '.new-field-form' do
          fill_in "field_name", with: "project_code"
          fill_in "field_label", with: "Code projet"
          select "Texte", from: "field_type"
          fill_in "field_value", with: "PROJ-2024-001"
          click_button "Ajouter"
        end
        
        # Ajouter un autre champ
        click_button "Ajouter un champ"
        
        within '.new-field-form' do
          fill_in "field_name", with: "priority_level"
          fill_in "field_label", with: "Niveau de priorité"
          select "Nombre", from: "field_type"
          fill_in "field_value", with: "1"
          click_button "Ajouter"
        end
        
        click_button "Enregistrer"
      end
      
      within '.document-metadata' do
        expect(page).to have_content("Code projet: PROJ-2024-001")
        expect(page).to have_content("Niveau de priorité: 1")
      end
    end
  end
  
  describe "search by tags and metadata", js: true do
    let!(:doc2) { create(:document, title: "Facture 2024", space: space) }
    let!(:doc3) { create(:document, title: "Rapport Annuel", space: space) }
    let!(:tag_urgent) { create(:tag, name: "Urgent", organization: organization) }
    let!(:tag_finance) { create(:tag, name: "Finance", organization: organization) }
    
    before do
      # Ajouter des tags
      document.tags << tag_urgent
      doc2.tags << [tag_urgent, tag_finance]
      doc3.tags << tag_finance
      
      # Ajouter des métadonnées
      document.metadata.create!(key: "client", value: "ABC Corp")
      doc2.metadata.create!(key: "amount", value: "5000")
      doc3.metadata.create!(key: "year", value: "2024")
    end
    
    it "filters documents by tags" do
      visit ged_space_path(space)
      
      # Ouvrir les filtres
      click_button "Filtres"
      
      within '#filtersPanel' do
        # Filtrer par tag
        within '.tag-filters' do
          check "tag_urgent"
        end
        
        click_button "Appliquer"
      end
      
      # Seuls les documents avec le tag Urgent doivent apparaître
      expect(page).to have_content("Contrat Client ABC")
      expect(page).to have_content("Facture 2024")
      expect(page).not_to have_content("Rapport Annuel")
      
      # Ajouter un autre filtre
      within '#filtersPanel' do
        within '.tag-filters' do
          check "tag_finance"
        end
        
        # Changer l'opérateur
        select "Tous les tags", from: "tag_operator"
        
        click_button "Appliquer"
      end
      
      # Seul doc2 a les deux tags
      expect(page).not_to have_content("Contrat Client ABC")
      expect(page).to have_content("Facture 2024")
      expect(page).not_to have_content("Rapport Annuel")
    end
    
    it "searches by metadata values" do
      visit ged_space_path(space)
      
      # Utiliser la recherche avancée
      click_button "Recherche avancée"
      
      within '#advancedSearchModal' do
        # Ajouter une condition de métadonnée
        click_button "Ajouter une condition"
        
        select "Métadonnée", from: "condition_type_1"
        fill_in "metadata_key_1", with: "client"
        select "contient", from: "metadata_operator_1"
        fill_in "metadata_value_1", with: "ABC"
        
        click_button "Rechercher"
      end
      
      # Seul le document avec client=ABC Corp doit apparaître
      expect(page).to have_content("Contrat Client ABC")
      expect(page).not_to have_content("Facture 2024")
      expect(page).not_to have_content("Rapport Annuel")
      
      # Recherche combinée
      click_button "Recherche avancée"
      
      within '#advancedSearchModal' do
        # Condition existante + nouvelle condition
        click_button "Ajouter une condition"
        
        select "Tag", from: "condition_type_2"
        select "Urgent", from: "tag_condition_2"
        
        select "OU", from: "condition_operator"
        
        click_button "Rechercher"
      end
      
      # Documents avec client ABC OU tag Urgent
      expect(page).to have_content("Contrat Client ABC")
      expect(page).to have_content("Facture 2024")
      expect(page).not_to have_content("Rapport Annuel")
    end
  end
  
  describe "bulk metadata operations", js: true do
    let!(:doc2) { create(:document, title: "Document 2", space: space) }
    let!(:doc3) { create(:document, title: "Document 3", space: space) }
    
    it "applies tags to multiple documents" do
      visit ged_space_path(space)
      
      # Sélectionner plusieurs documents
      click_button "Sélection multiple"
      
      check "select_document_#{document.id}"
      check "select_document_#{doc2.id}"
      check "select_document_#{doc3.id}"
      
      within '.bulk-actions-bar' do
        click_button "Gérer les tags"
      end
      
      within '#bulkTagsModal' do
        # Ajouter des tags
        fill_in "bulk_tags", with: "Traité, Archive, 2024"
        
        # Options d'application
        choose "add_tags" # vs replace_tags
        
        click_button "Appliquer aux documents"
      end
      
      expect(page).to have_content("Tags appliqués à 3 documents")
      
      # Vérifier un document
      visit ged_document_path(document)
      
      within '.document-tags' do
        expect(page).to have_content("Traité")
        expect(page).to have_content("Archive")
        expect(page).to have_content("2024")
      end
    end
    
    it "applies metadata template to multiple documents" do
      metadata_template = create(:metadata_template, 
        name: "Template Standard",
        organization: organization
      )
      
      visit ged_space_path(space)
      
      click_button "Sélection multiple"
      
      check "select_document_#{document.id}"
      check "select_document_#{doc2.id}"
      
      within '.bulk-actions-bar' do
        click_button "Appliquer un modèle"
      end
      
      within '#bulkTemplateModal' do
        select "Template Standard", from: "template_id"
        
        # Option pour écraser les métadonnées existantes
        check "overwrite_existing"
        
        click_button "Appliquer le modèle"
      end
      
      expect(page).to have_content("Modèle appliqué à 2 documents")
    end
  end
  
  describe "metadata inheritance", js: true do
    let(:folder) { create(:folder, name: "Contrats 2024", space: space) }
    
    it "inherits metadata from parent folder" do
      # Définir des métadonnées sur le dossier
      visit ged_folder_path(folder)
      
      click_button "Propriétés du dossier"
      
      within '#folderPropertiesModal' do
        click_link "Métadonnées par défaut"
        
        # Définir des métadonnées héritables
        check "enable_inheritance"
        
        fill_in "default_year", with: "2024"
        fill_in "default_department", with: "Juridique"
        select "Contrat", from: "default_type"
        
        click_button "Enregistrer"
      end
      
      # Uploader un document dans ce dossier
      click_button "Nouveau Document"
      
      within '#uploadModal' do
        fill_in "document_title", with: "Nouveau Contrat"
        attach_file "document_file", Rails.root.join("spec/fixtures/test_document.pdf")
        
        # Les métadonnées doivent être pré-remplies
        expect(find_field("year").value).to eq("2024")
        expect(find_field("department").value).to eq("Juridique")
        expect(find_field("type").value).to eq("Contrat")
        
        click_button "Télécharger"
      end
      
      # Vérifier que les métadonnées ont été appliquées
      document = Document.last
      visit ged_document_path(document)
      
      within '.document-metadata' do
        expect(page).to have_content("Année: 2024")
        expect(page).to have_content("Département: Juridique")
        expect(page).to have_content("Type: Contrat")
      end
    end
  end
end