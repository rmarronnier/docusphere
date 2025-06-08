require 'rails_helper'

RSpec.describe "Search Autocomplete", type: :system, js: true do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  
  before do
    login_as(user, scope: :user)
  end
  
  describe "search bar in navbar" do
    before do
      create(:document, title: "Financial Report 2023", space: space, uploaded_by: user)
      create(:document, title: "Financial Budget 2024", space: space, uploaded_by: user)
      create(:document, title: "Meeting Notes", space: space, uploaded_by: user)
      visit ged_dashboard_path
    end
    
    it "shows search input in navbar" do
      expect(page).to have_css('input[placeholder="Rechercher un document..."]')
    end
    
    it "shows suggestions when typing" do
      search_input = find('input[placeholder="Rechercher un document..."]')
      search_input.fill_in with: "Fin"
      
      # Wait for suggestions to appear
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"]:not(.hidden)', wait: 2)
      
      within '[data-search-autocomplete-target="suggestions"]' do
        expect(page).to have_content("Financial Report 2023")
        expect(page).to have_content("Financial Budget 2024")
        expect(page).not_to have_content("Meeting Notes")
      end
    end
    
    it "highlights matching text in suggestions" do
      search_input = find('input[placeholder="Rechercher un document..."]')
      search_input.fill_in with: "Report"
      
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"]:not(.hidden)', wait: 2)
      expect(page).to have_css('mark', text: 'Report')
    end
    
    it "navigates to document when clicking suggestion" do
      search_input = find('input[placeholder="Rechercher un document..."]')
      search_input.fill_in with: "Meeting"
      
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"]:not(.hidden)', wait: 2)
      
      within '[data-search-autocomplete-target="suggestions"]' do
        click_link "Meeting Notes"
      end
      
      expect(page).to have_current_path(ged_document_path(Document.find_by(title: "Meeting Notes")))
    end
    
    it "hides suggestions when clicking outside" do
      search_input = find('input[placeholder="Rechercher un document..."]')
      search_input.fill_in with: "Financial"
      
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"]:not(.hidden)', wait: 2)
      
      # Click outside
      find('body').click
      
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"].hidden')
    end
    
    it "submits search form on Enter" do
      search_input = find('input[placeholder="Rechercher un document..."]')
      search_input.fill_in with: "Financial"
      search_input.send_keys :return
      
      expect(page).to have_current_path(search_path, ignore_query: false)
      expect(page).to have_content("2 résultats pour \"Financial\"")
    end
    
    it "supports keyboard navigation" do
      search_input = find('input[placeholder="Rechercher un document..."]')
      search_input.fill_in with: "Financial"
      
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"]:not(.hidden)', wait: 2)
      
      # Navigate with arrow keys
      search_input.send_keys :arrow_down
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"] a.bg-gray-50')
      
      search_input.send_keys :arrow_down
      suggestions = all('[data-search-autocomplete-target="suggestions"] a')
      expect(suggestions[1]).to have_css('.bg-gray-50')
      
      # Select with Enter
      search_input.send_keys :return
      expect(page).to have_current_path(/\/ged\/documents\/\d+/)
    end
  end
  
  describe "search results page" do
    before do
      create(:document, title: "Contract ABC", description: "Important legal document", space: space, uploaded_by: user)
      create(:document, title: "Invoice 123", description: "Payment for services", space: space, uploaded_by: user)
    end
    
    it "displays search results" do
      visit search_path(q: "Contract")
      
      expect(page).to have_content("1 résultat pour \"Contract\"")
      expect(page).to have_content("Contract ABC")
      expect(page).to have_content("Important legal document")
      expect(page).not_to have_content("Invoice 123")
    end
    
    it "shows no results message" do
      visit search_path(q: "NonExistent")
      
      expect(page).to have_content("Aucun résultat trouvé")
      expect(page).to have_content("Aucun document ne correspond à votre recherche \"NonExistent\"")
      expect(page).to have_link("Retour au tableau de bord")
    end
    
    it "highlights search terms in results" do
      visit search_path(q: "legal")
      
      expect(page).to have_css('mark', text: 'legal')
    end
  end
end