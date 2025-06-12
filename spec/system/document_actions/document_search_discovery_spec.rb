require 'rails_helper'

RSpec.describe 'Document Search and Discovery Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let!(:documents) do
    [
      create(:document, title: 'Contrat de location 2025.pdf', content: 'contrat bail commercial', parent: create(:folder), tags: ['contrat', 'immobilier']),
      create(:document, title: 'Rapport financier Q4.xlsx', content: 'bilan comptable résultats', parent: create(:folder), tags: ['finance', 'rapport']),
      create(:document, title: 'Plan architectural.dwg', content: 'plans étage bureaux', parent: create(:folder), tags: ['technique', 'plan']),
      create(:document, title: 'Présentation projet.pptx', content: 'roadmap planning stratégie', parent: create(:folder), tags: ['présentation', 'projet']),
      create(:document, title: 'Facture ACME-2025-001.pdf', content: 'facture services prestation', parent: create(:folder), tags: ['facture', 'comptabilité'])
    ]
  end
  
  before do
    sign_in user
    # Index documents for search
    documents.each { |doc| doc.update_search_index }
  end
  
  describe 'Quick Search' do
    it 'performs instant search with autocomplete' do
      visit root_path
      
      within '.navbar-search' do
        fill_in 'search', with: 'cont'
        
        # Autocomplete suggestions
        within '.search-suggestions' do
          expect(page).to have_content('contrat')
          expect(page).to have_content('Contrat de location 2025.pdf')
          expect(page).to have_css('.suggestion-type', text: 'Documents')
          expect(page).to have_css('.suggestion-type', text: 'Tags')
        end
        
        # Click suggestion
        click_link 'Contrat de location 2025.pdf'
      end
      
      expect(current_path).to eq(ged_document_path(documents[0]))
    end
    
    it 'shows recent searches' do
      # Perform some searches
      visit search_path(q: 'finance')
      visit search_path(q: 'projet')
      visit search_path(q: 'contrat')
      
      visit root_path
      
      within '.navbar-search' do
        find('#search').click
        
        within '.recent-searches' do
          expect(page).to have_content('Recherches récentes')
          expect(page).to have_link('contrat')
          expect(page).to have_link('projet')
          expect(page).to have_link('finance')
          
          # Clear history
          click_button 'Effacer l\'historique'
        end
        
        expect(page).not_to have_css('.recent-searches')
      end
    end
  end
  
  describe 'Advanced Search' do
    it 'searches with multiple criteria' do
      visit advanced_search_path
      
      within '.advanced-search-form' do
        # Text search
        fill_in 'Rechercher', with: 'contrat'
        
        # File type filter
        within '.file-type-filters' do
          check 'PDF'
          check 'Word'
        end
        
        # Date range
        fill_in 'Date début', with: 1.month.ago.to_date
        fill_in 'Date fin', with: Date.current
        
        # Size range
        select '1 MB - 10 MB', from: 'Taille'
        
        # Tags
        fill_in 'Tags', with: 'immobilier'
        
        # Metadata
        click_button 'Plus de critères'
        
        within '.metadata-filters' do
          select 'Contrat', from: 'Catégorie'
          fill_in 'Téléversé par', with: user.name
        end
        
        click_button 'Rechercher'
      end
      
      within '.search-results' do
        expect(page).to have_content('1 résultat')
        expect(page).to have_content('Contrat de location 2025.pdf')
        
        # Refine search
        within '.search-facets' do
          expect(page).to have_content('Affiner la recherche')
          
          # Facets
          within '.facet-type' do
            expect(page).to have_content('PDF (1)')
            expect(page).to have_content('Excel (0)')
          end
          
          within '.facet-tags' do
            expect(page).to have_content('contrat (1)')
            expect(page).to have_content('immobilier (1)')
          end
        end
      end
    end
    
    it 'saves and manages search queries' do
      visit advanced_search_path
      
      # Configure search
      fill_in 'Rechercher', with: 'rapport finance'
      check 'Excel'
      select 'Ce mois', from: 'Période'
      
      click_button 'Rechercher'
      
      # Save search
      click_button 'Sauvegarder cette recherche'
      
      within '.save-search-modal' do
        fill_in 'Nom', with: 'Rapports financiers mensuels'
        fill_in 'Description', with: 'Tous les rapports Excel du mois en cours'
        check 'M\'alerter des nouveaux résultats'
        select 'Quotidien', from: 'Fréquence des alertes'
        
        click_button 'Sauvegarder'
      end
      
      expect(page).to have_content('Recherche sauvegardée')
      
      # Access saved searches
      visit saved_searches_path
      
      expect(page).to have_content('Mes recherches sauvegardées')
      
      within '.saved-search-item', text: 'Rapports financiers mensuels' do
        expect(page).to have_content('rapport finance')
        expect(page).to have_content('Alertes: Quotidien')
        expect(page).to have_button('Exécuter')
        expect(page).to have_button('Modifier')
        expect(page).to have_button('Supprimer')
        
        click_button 'Exécuter'
      end
      
      expect(page).to have_content('Résultats de recherche')
      expect(page).to have_content('Rapport financier Q4.xlsx')
    end
  end
  
  describe 'Search Filters and Facets' do
    it 'filters results dynamically' do
      visit search_path(q: '')
      
      expect(page).to have_content("#{documents.count} documents")
      
      within '.search-filters' do
        # Type filter
        within '.filter-group', text: 'Type de fichier' do
          check 'PDF'
          
          expect(page).to have_content('2 documents') # Updated count
        end
        
        # Tag filter
        within '.filter-group', text: 'Tags' do
          check 'finance'
          
          expect(page).to have_content('1 document')
        end
        
        # Clear specific filter
        within '.active-filters' do
          expect(page).to have_css('.filter-tag', text: 'PDF')
          expect(page).to have_css('.filter-tag', text: 'finance')
          
          within '.filter-tag', text: 'PDF' do
            click_button '×'
          end
        end
        
        expect(page).to have_content('1 document') # Only finance tag active
        
        # Clear all filters
        click_button 'Réinitialiser les filtres'
        
        expect(page).to have_content("#{documents.count} documents")
      end
    end
    
    it 'sorts search results' do
      visit search_path(q: '')
      
      within '.search-toolbar' do
        # Default sort
        expect(page).to have_select('sort', selected: 'Pertinence')
        
        # Sort by name
        select 'Nom (A-Z)', from: 'sort'
        
        within '.search-results' do
          results = all('.result-item .document-name').map(&:text)
          expect(results).to eq(results.sort)
        end
        
        # Sort by date
        select 'Plus récent', from: 'sort'
        
        within '.search-results' do
          first_date = find('.result-item:first-child .document-date')['data-date']
          last_date = find('.result-item:last-child .document-date')['data-date']
          expect(first_date).to be >= last_date
        end
        
        # Sort by size
        select 'Taille (décroissant)', from: 'sort'
        
        within '.search-results' do
          sizes = all('.result-item .document-size').map { |el| el['data-size'].to_i }
          expect(sizes).to eq(sizes.sort.reverse)
        end
      end
    end
  end
  
  describe 'Full-Text Search' do
    it 'searches within document content' do
      visit search_path
      
      # Search for content
      fill_in 'q', with: 'bilan comptable'
      check 'Rechercher dans le contenu'
      click_button 'Rechercher'
      
      within '.search-results' do
        expect(page).to have_content('Rapport financier Q4.xlsx')
        
        # Highlighted excerpt
        within '.result-excerpt' do
          expect(page).to have_css('mark', text: 'bilan')
          expect(page).to have_css('mark', text: 'comptable')
          expect(page).to have_content('...bilan comptable résultats...')
        end
      end
      
      # OCR search for scanned documents
      scanned_doc = create(:document, 
        title: 'Scan_Contract.pdf',
        ocr_content: 'Ceci est un contrat scanné avec du texte reconnu par OCR',
        has_ocr: true
      )
      
      fill_in 'q', with: 'contrat scanné OCR'
      click_button 'Rechercher'
      
      within '.search-results' do
        expect(page).to have_content('Scan_Contract.pdf')
        
        within '.result-badges' do
          expect(page).to have_css('.ocr-badge', text: 'OCR')
        end
      end
    end
    
    it 'uses smart search with synonyms' do
      visit search_path
      
      # Search with synonym
      fill_in 'q', with: 'facture'
      check 'Recherche intelligente'
      click_button 'Rechercher'
      
      within '.search-info' do
        expect(page).to have_content('Recherche étendue activée')
        expect(page).to have_content('Inclut: invoice, bill, facturation')
      end
      
      within '.search-results' do
        expect(page).to have_content('Facture ACME-2025-001.pdf')
        # Would also find documents with "invoice" or "bill" if they existed
      end
      
      # Fuzzy search for typos
      fill_in 'q', with: 'raport' # Typo
      click_button 'Rechercher'
      
      within '.search-suggestions' do
        expect(page).to have_content('Vouliez-vous dire: rapport?')
        click_link 'rapport'
      end
      
      expect(page).to have_content('Rapport financier Q4.xlsx')
    end
  end
  
  describe 'Visual Search and Discovery' do
    it 'browses documents by visual grid' do
      visit ged_dashboard_path
      
      click_link 'Explorer visuellement'
      
      expect(page).to have_css('.visual-explorer')
      
      within '.view-options' do
        # Switch to thumbnail view
        click_button 'Vignettes'
        
        expect(page).to have_css('.thumbnail-grid')
        expect(page).to have_css('.document-thumbnail', count: documents.count)
        
        # Hover for preview
        first('.document-thumbnail').hover
        
        expect(page).to have_css('.quick-preview')
        expect(page).to have_content(documents.first.name)
        expect(page).to have_button('Aperçu rapide')
      end
      
      # Filter by visual attributes
      within '.visual-filters' do
        # Color-coded by type
        click_button 'PDF', class: 'type-filter-pdf'
        
        expect(page).to have_css('.document-thumbnail.type-pdf')
        expect(page).not_to have_css('.document-thumbnail.type-excel')
        
        # Size visualization
        click_button 'Taille'
        
        expect(page).to have_css('.size-indicator')
        # Documents shown with relative size indicators
      end
    end
    
    it 'discovers related documents' do
      document = documents.first
      
      visit ged_document_path(document)
      
      # Related documents section
      within '.related-documents' do
        expect(page).to have_content('Documents similaires')
        
        # By tags
        within '.related-by-tags' do
          expect(page).to have_content('Autres documents "contrat"')
          # Would show other contracts
        end
        
        # By folder
        within '.related-by-location' do
          expect(page).to have_content("Dans le même dossier")
          # Would show sibling documents
        end
        
        # By author
        within '.related-by-author' do
          expect(page).to have_content("Du même auteur")
          # Would show other docs by same uploader
        end
        
        # By content similarity
        within '.related-by-content' do
          expect(page).to have_content('Contenu similaire')
          # ML-based recommendations
        end
      end
      
      # Click to explore
      within '.related-by-tags' do
        click_link 'Voir tous les contrats'
      end
      
      expect(page).to have_content('Documents taggés "contrat"')
    end
  end
  
  describe 'Search Analytics and Insights' do
    it 'shows search trends and popular content' do
      visit search_analytics_path
      
      within '.search-trends' do
        expect(page).to have_content('Tendances de recherche')
        
        # Top searches
        within '.top-searches' do
          expect(page).to have_content('Recherches populaires')
          expect(page).to have_css('.search-term')
          expect(page).to have_css('.search-count')
        end
        
        # Trending tags
        within '.trending-tags' do
          expect(page).to have_css('.tag-cloud')
          expect(page).to have_css('.tag', minimum: 5)
          # Larger tags = more popular
        end
        
        # No results searches
        within '.failed-searches' do
          expect(page).to have_content('Recherches sans résultat')
          # Helps identify missing content
        end
      end
      
      # Personal search insights
      within '.personal-insights' do
        expect(page).to have_content('Vos habitudes de recherche')
        expect(page).to have_css('.search-frequency-chart')
        expect(page).to have_content('Documents les plus consultés')
      end
    end
  end
  
  describe 'Mobile Search Experience', js: true do
    it 'provides optimized mobile search' do
      page.driver.browser.manage.window.resize_to(375, 812)
      
      visit root_path
      
      # Mobile search trigger
      click_button 'search-mobile-trigger'
      
      # Full screen search
      expect(page).to have_css('.mobile-search-overlay')
      
      within '.mobile-search' do
        fill_in 'mobile-search', with: 'rapport'
        
        # Instant results
        within '.mobile-results' do
          expect(page).to have_content('Rapport financier Q4')
          
          # Swipe actions
          first('.result-item').swipe_left
          
          expect(page).to have_button('Télécharger')
          expect(page).to have_button('Partager')
        end
        
        # Voice search
        click_button 'voice-search'
        
        expect(page).to have_content('Parlez maintenant...')
        # Would use speech recognition API
        
        # Recent & suggested
        click_button 'Annuler'
        
        within '.search-suggestions' do
          expect(page).to have_content('Récent')
          expect(page).to have_content('Suggéré pour vous')
        end
      end
      
      # Filters bottom sheet
      click_button 'Filtres'
      
      within '.bottom-sheet' do
        expect(page).to have_content('Filtrer les résultats')
        
        # Quick filters
        within '.quick-filters' do
          click_button 'Cette semaine'
          click_button 'PDF'
          click_button 'Mes documents'
        end
        
        click_button 'Appliquer'
      end
      
      expect(page).to have_css('.active-filter-count', text: '3')
    end
  end
  
  describe 'Search API and Integration' do
    it 'exports search results' do
      visit search_path(q: 'rapport')
      
      within '.search-toolbar' do
        click_button 'Exporter'
        
        within '.export-options' do
          select 'CSV', from: 'format'
          check 'Inclure les métadonnées'
          check 'Inclure le chemin'
          
          click_button 'Exporter résultats'
        end
      end
      
      expect(page.response_headers['Content-Type']).to include('text/csv')
      expect(page.response_headers['Content-Disposition']).to include('search_results')
    end
    
    it 'generates search RSS feed' do
      saved_search = create(:saved_search, 
        user: user,
        query: 'finance rapport',
        name: 'Rapports financiers'
      )
      
      visit saved_search_rss_path(saved_search, format: :rss, token: saved_search.rss_token)
      
      expect(page).to have_content('Rapports financiers - DocuSphere')
      expect(page).to have_css('item')
      expect(page.body).to include('<rss')
    end
  end
end