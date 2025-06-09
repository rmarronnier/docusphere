require 'rails_helper'

RSpec.describe "Search Functionality", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  
  # Créer des documents avec différents attributs pour tester la recherche
  let!(:contract_doc) { create(:document, 
    title: "Contrat de Service ABC",
    description: "Contrat annuel de maintenance informatique",
    content: "Ce contrat définit les termes de service pour l'année 2024",
    space: space,
    uploaded_by: user
  )}
  
  let!(:invoice_doc) { create(:document,
    title: "Facture 2024-001",
    description: "Facture pour services rendus en janvier",
    content: "Montant total: 5000 EUR pour consulting",
    space: space,
    uploaded_by: user
  )}
  
  let!(:report_doc) { create(:document,
    title: "Rapport Mensuel Janvier",
    description: "Rapport d'activité du mois de janvier 2024",
    content: "Performance exceptionnelle ce mois avec 20% de croissance",
    space: space,
    uploaded_by: user
  )}
  
  before do
    login_as(user, scope: :user)
    
    # Ajouter des tags et métadonnées
    tag_urgent = create(:tag, name: "Urgent", organization: organization)
    tag_finance = create(:tag, name: "Finance", organization: organization)
    tag_2024 = create(:tag, name: "2024", organization: organization)
    
    contract_doc.tags << [tag_urgent, tag_2024]
    invoice_doc.tags << [tag_finance, tag_2024]
    report_doc.tags << tag_2024
    
    contract_doc.metadata.create!(key: "client", value: "ABC Corporation")
    contract_doc.metadata.create!(key: "value", value: "50000")
    invoice_doc.metadata.create!(key: "amount", value: "5000")
    invoice_doc.metadata.create!(key: "status", value: "paid")
  end
  
  describe "quick search from navbar", js: true do
    it "searches documents with autocomplete" do
      visit root_path
      
      # Utiliser la barre de recherche dans la navbar
      within '.navbar' do
        fill_in "search", with: "cont"
      end
      
      # Attendre les suggestions
      expect(page).to have_css('.search-suggestions', wait: 2)
      
      within '.search-suggestions' do
        expect(page).to have_content("Contrat de Service ABC")
        expect(page).to have_content("Contrat annuel de maintenance")
        expect(page).not_to have_content("Facture 2024-001")
        
        # Prévisualisation au survol
        find('.suggestion-item', text: "Contrat de Service ABC").hover
        expect(page).to have_css('.suggestion-preview')
        within '.suggestion-preview' do
          expect(page).to have_content("Tags: Urgent, 2024")
          expect(page).to have_content("Client: ABC Corporation")
        end
      end
      
      # Sélectionner une suggestion
      within '.search-suggestions' do
        click_link "Contrat de Service ABC"
      end
      
      expect(page).to have_current_path(ged_document_path(contract_doc))
    end
    
    it "navigates search results with keyboard" do
      visit root_path
      
      within '.navbar' do
        search_input = find('input[name="search"]')
        search_input.fill_in with: "2024"
      end
      
      expect(page).to have_css('.search-suggestions')
      
      # Navigation au clavier
      search_input = find('input[name="search"]')
      
      # Flèche bas pour sélectionner le premier résultat
      search_input.send_keys :down
      expect(page).to have_css('.suggestion-item.selected')
      
      # Flèche bas pour le second
      search_input.send_keys :down
      
      # Entrée pour ouvrir
      search_input.send_keys :return
      
      # Doit naviguer vers le document sélectionné
      expect(page).to have_current_path(/\/ged\/documents\/\d+/)
    end
    
    it "shows 'see all results' option" do
      visit root_path
      
      within '.navbar' do
        fill_in "search", with: "2024"
      end
      
      within '.search-suggestions' do
        # Tous les documents ont le tag 2024
        expect(page).to have_content("Contrat de Service ABC")
        expect(page).to have_content("Facture 2024-001")
        expect(page).to have_content("Rapport Mensuel Janvier")
        
        # Option pour voir tous les résultats
        click_link "Voir tous les résultats (3)"
      end
      
      # Redirection vers la page de résultats
      expect(page).to have_current_path(search_path(q: "2024"))
      expect(page).to have_content("3 résultats pour \"2024\"")
    end
  end
  
  describe "advanced search page", js: true do
    it "performs multi-criteria search" do
      visit search_path
      
      click_button "Recherche avancée"
      
      within '#advancedSearchForm' do
        # Critères de base
        fill_in "title_contains", with: "Contrat"
        fill_in "content_contains", with: "service"
        
        # Plage de dates
        fill_in "created_after", with: 1.week.ago.strftime("%Y-%m-%d")
        fill_in "created_before", with: Date.tomorrow.strftime("%Y-%m-%d")
        
        # Tags
        within '.tag-selector' do
          check "Urgent"
          check "2024"
        end
        
        # Type de fichier
        select "PDF", from: "file_type"
        
        # Métadonnées
        within '.metadata-filters' do
          click_button "Ajouter un filtre"
          fill_in "meta_key_1", with: "client"
          select "contient", from: "meta_operator_1"
          fill_in "meta_value_1", with: "ABC"
        end
        
        click_button "Rechercher"
      end
      
      # Vérifier les résultats
      within '.search-results' do
        expect(page).to have_content("1 résultat")
        expect(page).to have_content("Contrat de Service ABC")
        
        # Mise en évidence des termes recherchés
        expect(page).to have_css('mark', text: "Contrat")
        expect(page).to have_css('mark', text: "service")
      end
    end
    
    it "saves and loads search queries" do
      visit search_path
      
      # Effectuer une recherche
      fill_in "q", with: "finance 2024"
      click_button "Rechercher"
      
      # Sauvegarder la recherche
      click_button "Sauvegarder cette recherche"
      
      within '#saveSearchModal' do
        fill_in "search_name", with: "Documents financiers 2024"
        fill_in "search_description", with: "Tous les documents financiers de l'année"
        check "notify_new_results"
        
        click_button "Sauvegarder"
      end
      
      expect(page).to have_content("Recherche sauvegardée")
      
      # Charger une recherche sauvegardée
      visit search_path
      
      click_button "Recherches sauvegardées"
      
      within '#savedSearchesModal' do
        expect(page).to have_content("Documents financiers 2024")
        expect(page).to have_content("Notifications activées")
        
        click_link "Documents financiers 2024"
      end
      
      # La recherche doit être rechargée
      expect(find_field("q").value).to eq("finance 2024")
      within '.search-results' do
        expect(page).to have_content("Facture 2024-001")
      end
    end
    
    it "exports search results" do
      visit search_path(q: "2024")
      
      # Attendre les résultats
      expect(page).to have_css('.search-results')
      
      # Options d'export
      click_button "Exporter les résultats"
      
      within '#exportModal' do
        # Format
        choose "CSV"
        
        # Colonnes à inclure
        check "Titre"
        check "Description"
        check "Tags"
        check "Date de création"
        uncheck "Contenu"
        
        # Options supplémentaires
        check "include_metadata"
        fill_in "export_filename", with: "resultats_recherche_2024"
        
        click_button "Exporter"
      end
      
      # Vérifier le téléchargement
      expect(page).to have_content("Export en cours...")
      expect(page).to have_content("Export terminé", wait: 5)
      
      # Le fichier devrait être téléchargé
      expect(Downloads.last).to match(/resultats_recherche_2024.*\.csv/)
    end
  end
  
  describe "faceted search", js: true do
    it "filters results using facets" do
      # Créer plus de documents pour les facettes
      5.times do |i|
        create(:document, 
          title: "Document Test #{i}",
          space: space,
          created_at: i.days.ago
        )
      end
      
      visit search_path(q: "")
      
      # Les facettes doivent être affichées
      within '.search-facets' do
        # Facette par type
        within '.facet-group', text: "Type de fichier" do
          expect(page).to have_content("PDF (8)")
          expect(page).to have_content("Word (0)")
          
          check "PDF"
        end
        
        # Facette par date
        within '.facet-group', text: "Date de création" do
          expect(page).to have_content("Aujourd'hui")
          expect(page).to have_content("Cette semaine")
          expect(page).to have_content("Ce mois")
          
          check "Cette semaine"
        end
        
        # Facette par tags
        within '.facet-group', text: "Tags" do
          expect(page).to have_content("2024 (3)")
          expect(page).to have_content("Urgent (1)")
          expect(page).to have_content("Finance (1)")
          
          check "2024"
        end
      end
      
      # Les résultats doivent être filtrés
      within '.search-results' do
        expect(page).to have_content("3 résultats")
        expect(page).to have_content("Contrat de Service ABC")
        expect(page).to have_content("Facture 2024-001")
        expect(page).to have_content("Rapport Mensuel Janvier")
      end
      
      # Les filtres actifs doivent être affichés
      within '.active-filters' do
        expect(page).to have_content("PDF")
        expect(page).to have_content("Cette semaine")
        expect(page).to have_content("2024")
        
        # Possibilité de retirer un filtre
        within '.filter-tag', text: "2024" do
          click_button "×"
        end
      end
      
      # Mise à jour des résultats
      within '.search-results' do
        expect(page).to have_content("8 résultats")
      end
    end
    
    it "updates facet counts dynamically" do
      visit search_path
      
      # Recherche initiale
      fill_in "q", with: "rapport"
      click_button "Rechercher"
      
      within '.search-facets' do
        within '.facet-group', text: "Tags" do
          # Seul le document rapport a ces tags
          expect(page).to have_content("2024 (1)")
          expect(page).not_to have_content("Finance")
          expect(page).not_to have_content("Urgent")
        end
      end
      
      # Changer la recherche
      fill_in "q", with: ""
      click_button "Rechercher"
      
      within '.search-facets' do
        within '.facet-group', text: "Tags" do
          # Tous les tags doivent réapparaître
          expect(page).to have_content("2024 (3)")
          expect(page).to have_content("Finance (1)")
          expect(page).to have_content("Urgent (1)")
        end
      end
    end
  end
  
  describe "search within results", js: true do
    it "refines search results" do
      visit search_path(q: "2024")
      
      # Recherche initiale retourne 3 documents
      within '.search-results' do
        expect(page).to have_content("3 résultats")
      end
      
      # Affiner la recherche
      within '.refine-search' do
        fill_in "refine_query", with: "facture"
        click_button "Affiner"
      end
      
      # Seule la facture doit rester
      within '.search-results' do
        expect(page).to have_content("1 résultat")
        expect(page).to have_content("Facture 2024-001")
      end
      
      # L'historique de recherche doit montrer les deux termes
      within '.search-breadcrumb' do
        expect(page).to have_content("2024")
        expect(page).to have_content("facture")
        
        # Possibilité de revenir à la recherche précédente
        click_link "2024"
      end
      
      within '.search-results' do
        expect(page).to have_content("3 résultats")
      end
    end
  end
  
  describe "search suggestions and corrections", js: true do
    it "suggests spelling corrections" do
      visit search_path
      
      # Recherche avec faute d'orthographe
      fill_in "q", with: "raport"
      click_button "Rechercher"
      
      # Suggestion de correction
      within '.search-suggestions-banner' do
        expect(page).to have_content("Vouliez-vous dire : rapport ?")
        click_link "rapport"
      end
      
      # La recherche est relancée avec la correction
      expect(find_field("q").value).to eq("rapport")
      within '.search-results' do
        expect(page).to have_content("Rapport Mensuel Janvier")
      end
    end
    
    it "suggests related searches" do
      visit search_path(q: "contrat")
      
      within '.related-searches' do
        expect(page).to have_content("Recherches similaires:")
        expect(page).to have_link("contrat ABC")
        expect(page).to have_link("contrat service")
        expect(page).to have_link("contrat 2024")
        expect(page).to have_link("contrat maintenance")
      end
      
      # Cliquer sur une suggestion
      click_link "contrat maintenance"
      
      expect(find_field("q").value).to eq("contrat maintenance")
      within '.search-results' do
        expect(page).to have_content("Contrat de Service ABC")
        expect(page).to have_css('mark', text: "maintenance")
      end
    end
  end
  
  describe "search history and recent searches", js: true do
    it "tracks and displays search history" do
      # Effectuer plusieurs recherches
      visit search_path(q: "contrat")
      visit search_path(q: "facture")
      visit search_path(q: "rapport 2024")
      
      visit search_path
      
      # Les recherches récentes doivent être affichées
      within '.recent-searches' do
        expect(page).to have_content("Recherches récentes")
        expect(page).to have_link("rapport 2024")
        expect(page).to have_link("facture")
        expect(page).to have_link("contrat")
        
        # Timestamp
        expect(page).to have_content("il y a moins d'une minute")
      end
      
      # Effacer une recherche de l'historique
      within '.recent-searches' do
        within '.search-history-item', text: "facture" do
          click_button "×"
        end
      end
      
      expect(page).not_to have_link("facture")
      
      # Effacer tout l'historique
      click_button "Effacer l'historique"
      
      page.accept_confirm
      
      expect(page).to have_content("Aucune recherche récente")
    end
  end
  
  describe "search performance indicators", js: true do
    before do
      # Créer beaucoup de documents pour tester la performance
      50.times do |i|
        create(:document, 
          title: "Performance Test Doc #{i}",
          content: "Lorem ipsum dolor sit amet #{i}",
          space: space
        )
      end
    end
    
    it "displays search performance metrics" do
      visit search_path(q: "test")
      
      # Indicateurs de performance
      within '.search-stats' do
        expect(page).to have_content(/\d+ résultats/)
        expect(page).to have_content(/en \d+\.\d+ secondes/)
      end
      
      # Pagination
      within '.pagination' do
        expect(page).to have_link("2")
        expect(page).to have_link("Suivant")
      end
      
      # Changer le nombre de résultats par page
      within '.results-per-page' do
        select "50", from: "per_page"
      end
      
      within '.search-results' do
        expect(page).to have_css('.result-item', count: 50)
      end
    end
  end
end