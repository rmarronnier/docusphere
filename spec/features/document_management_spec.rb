require 'rails_helper'

RSpec.feature "Document Management", type: :feature do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let!(:folder) { create(:folder, name: "Documents", space: space) }
  
  before do
    login_as(user, scope: :user)
  end
  
  scenario "User uploads a new document" do
    visit ged_space_path(space)
    
    click_link "Documents"
    expect(page).to have_current_path(ged_folder_path(folder))
    
    click_button "Nouveau Document"
    
    # Sans JS, on a un formulaire standard
    expect(page).to have_current_path(new_ged_document_path)
    
    # Remplir le formulaire
    fill_in "Titre", with: "Rapport Mensuel"
    fill_in "Description", with: "Rapport d'activité du mois"
    select space.name, from: "Espace"
    attach_file "Fichier", Rails.root.join("spec/fixtures/test_document.pdf")
    
    click_button "Créer"
    
    # Vérifier la création
    expect(page).to have_content("Document créé avec succès")
    expect(page).to have_content("Rapport Mensuel")
    expect(page).to have_content("Rapport d'activité du mois")
    expect(page).to have_content("test_document.pdf")
    
    # Vérifier le statut de traitement
    expect(page).to have_content("En cours de traitement")
  end
  
  scenario "User edits document metadata" do
    document = create(:document, 
      title: "Document Original",
      folder: folder,
      space: space,
      user: user
    )
    
    visit ged_document_path(document)
    
    click_link "Modifier"
    
    expect(page).to have_current_path(edit_ged_document_path(document))
    
    # Modifier les informations
    fill_in "Titre", with: "Document Modifié"
    fill_in "Description", with: "Nouvelle description"
    
    click_button "Enregistrer"
    
    expect(page).to have_content("Document mis à jour avec succès")
    expect(page).to have_content("Document Modifié")
    expect(page).to have_content("Nouvelle description")
  end
  
  scenario "User downloads a document" do
    document = create(:document, 
      title: "Document à télécharger",
      space: space,
      processing_status: 'completed'
    )
    
    # Attacher un fichier
    document.file.attach(
      io: File.open(Rails.root.join("spec/fixtures/test_document.pdf")),
      filename: "test.pdf"
    )
    
    visit ged_document_path(document)
    
    # Le lien de téléchargement doit être présent
    expect(page).to have_link("Télécharger", href: rails_blob_path(document.file, disposition: "attachment"))
    
    # Cliquer déclenche le téléchargement (difficile à tester sans JS)
    download_link = find_link("Télécharger")
    expect(download_link['href']).to include("/rails/active_storage/blobs")
  end
  
  scenario "User deletes a document" do
    document = create(:document, 
      title: "Document à supprimer",
      space: space,
      user: user
    )
    
    visit ged_document_path(document)
    
    # Sans JS, utiliser un formulaire de suppression
    click_link "Supprimer"
    
    # Page de confirmation
    expect(page).to have_content("Êtes-vous sûr de vouloir supprimer ce document ?")
    expect(page).to have_content("Document à supprimer")
    
    click_button "Confirmer la suppression"
    
    expect(page).to have_content("Document supprimé avec succès")
    expect(page).to have_current_path(ged_space_path(space))
    expect(page).not_to have_content("Document à supprimer")
  end
  
  scenario "User moves document to another folder" do
    source_folder = folder
    target_folder = create(:folder, name: "Archives", space: space)
    document = create(:document, 
      title: "Document à déplacer",
      folder: source_folder,
      space: space
    )
    
    visit ged_document_path(document)
    
    click_link "Déplacer"
    
    expect(page).to have_content("Déplacer le document")
    
    select "Archives", from: "Dossier de destination"
    
    click_button "Déplacer"
    
    expect(page).to have_content("Document déplacé avec succès")
    
    # Vérifier le nouveau chemin
    visit ged_folder_path(target_folder)
    expect(page).to have_content("Document à déplacer")
    
    # Vérifier qu'il n'est plus dans l'ancien dossier
    visit ged_folder_path(source_folder)
    expect(page).not_to have_content("Document à déplacer")
  end
  
  scenario "User creates a new version of document" do
    document = create(:document, 
      title: "Document versionné",
      space: space,
      user: user
    )
    
    document.file.attach(
      io: File.open(Rails.root.join("spec/fixtures/test_document.pdf")),
      filename: "version1.pdf"
    )
    
    visit ged_document_path(document)
    
    click_link "Nouvelle version"
    
    # Formulaire d'upload de nouvelle version
    attach_file "Nouveau fichier", Rails.root.join("spec/fixtures/test_document.pdf")
    fill_in "Notes de version", with: "Corrections mineures"
    
    click_button "Créer la version"
    
    expect(page).to have_content("Nouvelle version créée avec succès")
    
    # Voir l'historique des versions
    click_link "Historique des versions"
    
    within ".versions-list" do
      expect(page).to have_content("Version 2")
      expect(page).to have_content("Version 1")
      expect(page).to have_content("Corrections mineures")
    end
  end
  
  scenario "User searches documents by title" do
    create(:document, title: "Contrat Client ABC", space: space)
    create(:document, title: "Facture 2024", space: space)
    create(:document, title: "Rapport Client XYZ", space: space)
    
    visit ged_space_path(space)
    
    # Formulaire de recherche simple
    fill_in "search", with: "Client"
    click_button "Rechercher"
    
    # Résultats
    expect(page).to have_content("2 résultats trouvés")
    expect(page).to have_content("Contrat Client ABC")
    expect(page).to have_content("Rapport Client XYZ")
    expect(page).not_to have_content("Facture 2024")
    
    # Affiner la recherche
    fill_in "search", with: "Client ABC"
    click_button "Rechercher"
    
    expect(page).to have_content("1 résultat trouvé")
    expect(page).to have_content("Contrat Client ABC")
  end
  
  scenario "User filters documents by date" do
    old_doc = create(:document, 
      title: "Vieux document",
      space: space,
      created_at: 2.years.ago
    )
    
    recent_doc = create(:document,
      title: "Document récent",
      space: space,
      created_at: 2.days.ago
    )
    
    visit ged_space_path(space)
    
    # Ouvrir les filtres
    click_link "Filtres avancés"
    
    # Filtrer par date
    fill_in "date_from", with: 1.week.ago.to_date
    fill_in "date_to", with: Date.today
    
    click_button "Appliquer les filtres"
    
    expect(page).to have_content("Document récent")
    expect(page).not_to have_content("Vieux document")
    
    # Réinitialiser les filtres
    click_link "Réinitialiser"
    
    expect(page).to have_content("Document récent")
    expect(page).to have_content("Vieux document")
  end
  
  scenario "User exports document list" do
    5.times do |i|
      create(:document, 
        title: "Document #{i}",
        space: space,
        created_at: i.days.ago
      )
    end
    
    visit ged_space_path(space)
    
    click_link "Exporter"
    
    # Choisir le format
    expect(page).to have_content("Exporter les documents")
    
    choose "CSV"
    check "Inclure les métadonnées"
    
    click_button "Exporter"
    
    # Le téléchargement devrait commencer
    expect(page).to have_content("Export en cours...")
    
    # Avec une vraie implémentation, on vérifierait le fichier téléchargé
    expect(page.response_headers['Content-Type']).to include('text/csv') if page.respond_to?(:response_headers)
  end
  
  scenario "User manages document permissions" do
    document = create(:document, 
      title: "Document privé",
      space: space,
      user: user
    )
    
    other_user = create(:user, organization: user.organization)
    
    visit ged_document_path(document)
    
    click_link "Permissions"
    
    # Ajouter des permissions
    within "#user_#{other_user.id}" do
      check "Lecture"
      uncheck "Écriture"
      uncheck "Suppression"
    end
    
    click_button "Enregistrer les permissions"
    
    expect(page).to have_content("Permissions mises à jour")
    
    # Se connecter en tant qu'autre utilisateur
    logout(:user)
    login_as(other_user, scope: :user)
    
    visit ged_document_path(document)
    
    # Peut voir mais pas modifier
    expect(page).to have_content("Document privé")
    expect(page).to have_link("Télécharger")
    expect(page).not_to have_link("Modifier")
    expect(page).not_to have_link("Supprimer")
  end
  
  scenario "User views document activity log" do
    document = create(:document, 
      title: "Document suivi",
      space: space,
      user: user
    )
    
    # Simuler des activités
    document.update!(title: "Document renommé")
    
    other_user = create(:user, organization: user.organization)
    create(:document_share, 
      document: document,
      shared_with: other_user,
      shared_by: user
    )
    
    visit ged_document_path(document)
    
    click_link "Activité"
    
    within ".activity-log" do
      expect(page).to have_content("#{user.full_name} a créé le document")
      expect(page).to have_content("#{user.full_name} a modifié le titre")
      expect(page).to have_content("#{user.full_name} a partagé avec #{other_user.full_name}")
      
      # Timestamps
      expect(page).to have_content("il y a moins d'une minute")
    end
  end
end