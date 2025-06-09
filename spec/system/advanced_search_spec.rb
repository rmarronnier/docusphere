require 'rails_helper'

RSpec.describe 'Advanced Search', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space1) { create(:space, organization: organization, name: 'Finance') }
  let(:space2) { create(:space, organization: organization, name: 'HR') }
  let(:tag1) { create(:tag, organization: organization, name: 'Important', color: 'bg-red-100') }
  let(:tag2) { create(:tag, organization: organization, name: 'Archive', color: 'bg-gray-100') }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
  end
  
  describe 'Navigation to advanced search' do
    it 'provides link from regular search page' do
      visit search_path
      
      expect(page).to have_link('Recherche avancée')
      
      click_link 'Recherche avancée'
      
      expect(page).to have_current_path(advanced_search_path)
      expect(page).to have_content('Recherche avancée')
      expect(page).to have_content('Utilisez les filtres ci-dessous')
    end
    
    it 'shows advanced search link when no results' do
      visit search_path
      
      within('.bg-white.shadow.rounded-lg.p-6.text-center') do
        expect(page).to have_link('Recherche avancée')
      end
    end
  end
  
  describe 'Advanced search form' do
    before do
      visit advanced_search_path
    end
    
    it 'displays all filter options' do
      # Text search
      expect(page).to have_field('Recherche textuelle')
      
      # Dropdowns
      expect(page).to have_select('Espace')
      expect(page).to have_select('Créé par')
      expect(page).to have_select('Type de fichier')
      expect(page).to have_select('Statut')
      
      # Date fields
      expect(page).to have_field('Du')
      expect(page).to have_field('Au')
      
      # Tags
      expect(page).to have_content('Tags')
      expect(page).to have_content(tag1.name)
      expect(page).to have_content(tag2.name)
      
      # Sort options
      expect(page).to have_select('Trier par')
    end
    
    it 'populates space dropdown' do
      within('select[name="space_id"]') do
        expect(page).to have_content('Tous les espaces')
        expect(page).to have_content(space1.name)
        expect(page).to have_content(space2.name)
      end
    end
    
    it 'populates user dropdown' do
      other_user = create(:user, organization: organization, first_name: 'John', last_name: 'Doe')
      
      visit advanced_search_path
      
      within('select[name="uploaded_by_id"]') do
        expect(page).to have_content('Tous les utilisateurs')
        expect(page).to have_content(user.full_name)
        expect(page).to have_content('John Doe')
      end
    end
  end
  
  describe 'Performing advanced searches' do
    let!(:doc1) do
      create(:document, 
        space: space1, 
        uploaded_by: user,
        title: 'Financial Report 2024',
        description: 'Annual financial statements',
        created_at: 1.month.ago)
    end
    
    let!(:doc2) do
      create(:document,
        space: space2,
        uploaded_by: user,
        title: 'HR Policy Manual',
        description: 'Company policies and procedures',
        created_at: 2.weeks.ago)
    end
    
    let!(:doc3) do
      create(:document,
        space: space1,
        uploaded_by: user,
        title: 'Budget Analysis',
        description: 'Q1 budget review',
        created_at: 1.week.ago)
    end
    
    before do
      doc1.tags << tag1
      doc2.tags << tag2
      doc3.tags << tag1
    end
    
    it 'searches with text query' do
      visit advanced_search_path
      
      fill_in 'Recherche textuelle', with: 'Budget'
      click_button 'Rechercher'
      
      expect(page).to have_content('1 résultat')
      expect(page).to have_content('Budget Analysis')
      expect(page).not_to have_content('Financial Report')
      expect(page).not_to have_content('HR Policy')
    end
    
    it 'filters by space' do
      visit advanced_search_path
      
      select 'Finance', from: 'Espace'
      click_button 'Rechercher'
      
      expect(page).to have_content('2 résultats')
      expect(page).to have_content('Financial Report')
      expect(page).to have_content('Budget Analysis')
      expect(page).not_to have_content('HR Policy')
    end
    
    it 'filters by tags' do
      visit advanced_search_path
      
      check tag1.name
      click_button 'Rechercher'
      
      expect(page).to have_content('2 résultats')
      expect(page).to have_content('Financial Report')
      expect(page).to have_content('Budget Analysis')
      expect(page).not_to have_content('HR Policy')
    end
    
    it 'filters by date range' do
      visit advanced_search_path
      
      fill_in 'Du', with: 3.weeks.ago.to_date
      fill_in 'Au', with: Date.today
      click_button 'Rechercher'
      
      expect(page).to have_content('2 résultats')
      expect(page).to have_content('HR Policy')
      expect(page).to have_content('Budget Analysis')
      expect(page).not_to have_content('Financial Report')
    end
    
    it 'combines multiple filters' do
      visit advanced_search_path
      
      fill_in 'Recherche textuelle', with: 'Report'
      select 'Finance', from: 'Espace'
      check tag1.name
      click_button 'Rechercher'
      
      expect(page).to have_content('1 résultat')
      expect(page).to have_content('Financial Report')
      expect(page).not_to have_content('Budget Analysis')
      expect(page).not_to have_content('HR Policy')
    end
    
    it 'sorts results' do
      visit advanced_search_path
      
      select 'Finance', from: 'Espace'
      select 'Titre (A-Z)', from: 'Trier par'
      click_button 'Rechercher'
      
      # Check order - Budget Analysis should come before Financial Report
      results = all('.bg-white.shadow ul li')
      expect(results[0]).to have_content('Budget Analysis')
      expect(results[1]).to have_content('Financial Report')
    end
  end
  
  describe 'File type filtering' do
    before do
      # Create documents with different file types
      pdf_doc = create(:document, space: space1, uploaded_by: user, title: 'PDF Document')
      word_doc = create(:document, space: space1, uploaded_by: user, title: 'Word Document')
      
      # Attach files
      pdf_doc.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/sample.pdf')),
        filename: 'sample.pdf',
        content_type: 'application/pdf'
      )
      
      word_doc.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/sample_document.docx')),
        filename: 'sample.docx',
        content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      )
    end
    
    it 'filters by PDF files' do
      visit advanced_search_path
      
      select 'PDF', from: 'Type de fichier'
      click_button 'Rechercher'
      
      expect(page).to have_content('1 résultat')
      expect(page).to have_content('PDF Document')
      expect(page).not_to have_content('Word Document')
    end
    
    it 'filters by Word files' do
      visit advanced_search_path
      
      select 'Word', from: 'Type de fichier'
      click_button 'Rechercher'
      
      expect(page).to have_content('1 résultat')
      expect(page).to have_content('Word Document')
      expect(page).not_to have_content('PDF Document')
    end
  end
  
  describe 'Search result display' do
    before do
      create(:document, space: space1, uploaded_by: user, title: 'Test Document')
      
      visit advanced_search_path
      click_button 'Rechercher'
    end
    
    it 'shows advanced search indicator' do
      expect(page).to have_content('avec filtres avancés')
    end
    
    it 'maintains advanced filters form' do
      expect(page).to have_css('form[action*="search"]')
      expect(page).to have_field('space_id')
      expect(page).to have_button('Appliquer les filtres')
    end
    
    it 'allows modifying filters' do
      select 'Finance', from: 'space_id'
      click_button 'Appliquer les filtres'
      
      expect(page).to have_content('1 résultat')
      expect(page).to have_content('Test Document')
    end
    
    it 'allows resetting filters' do
      click_link 'Réinitialiser'
      
      expect(page).to have_current_path(search_path)
      expect(page).not_to have_content('avec filtres avancés')
    end
  end
  
  describe 'Empty states' do
    it 'shows no results message with applied filters' do
      visit advanced_search_path
      
      fill_in 'Recherche textuelle', with: 'NonexistentDocument'
      click_button 'Rechercher'
      
      expect(page).to have_content('Aucun résultat trouvé')
      expect(page).to have_content('Aucun document ne correspond à votre recherche')
    end
  end
  
  describe 'Help section' do
    it 'displays search tips' do
      visit advanced_search_path
      
      expect(page).to have_content('Conseils de recherche')
      expect(page).to have_content('Utilisez plusieurs filtres pour affiner vos résultats')
      expect(page).to have_content('La recherche textuelle cherche dans le titre')
    end
  end
end