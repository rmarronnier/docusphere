require 'rails_helper'

RSpec.describe 'Tag Management', type: :system do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  
  describe 'Viewing tags' do
    let!(:tag1) { create(:tag, organization: organization, name: 'Important', color: 'bg-red-100') }
    let!(:tag2) { create(:tag, organization: organization, name: 'Archive', color: 'bg-gray-100') }
    
    before do
      login_as(regular_user, scope: :user)
    end
    
    it 'displays tags in the navigation' do
      visit root_path
      
      expect(page).to have_link('Tags')
    end
    
    it 'shows all organization tags' do
      visit tags_path
      
      expect(page).to have_content('Tags')
      expect(page).to have_content('Important')
      expect(page).to have_content('Archive')
      expect(page).to have_content('0 document')
    end
    
    it 'allows searching tags' do
      visit tags_path
      
      fill_in 'search', with: 'Import'
      click_button 'Rechercher'
      
      expect(page).to have_content('Important')
      expect(page).not_to have_content('Archive')
    end
    
    it 'shows tag details' do
      document = create(:document, space: space, uploaded_by: regular_user)
      document.tags << tag1
      
      visit tag_path(tag1)
      
      expect(page).to have_content('Important')
      expect(page).to have_content('1 document')
      expect(page).to have_content(document.title)
      expect(page).to have_css('.bg-red-100')
    end
  end
  
  describe 'Managing tags as admin' do
    before do
      login_as(admin, scope: :user)
    end
    
    it 'allows creating a new tag' do
      visit tags_path
      click_link 'Nouveau tag'
      
      fill_in 'Nom du tag', with: 'Urgent'
      fill_in 'Description', with: 'Documents nécessitant une action immédiate'
      select 'Priorité', from: 'Type de tag'
      find('label', text: 'bg-yellow-100').click
      
      click_button 'Créer le tag'
      
      expect(page).to have_content('Tag créé avec succès')
      expect(page).to have_content('Urgent')
      expect(page).to have_content('Documents nécessitant une action immédiate')
      expect(page).to have_content('Priorité')
      expect(page).to have_css('.bg-yellow-100')
    end
    
    it 'validates tag creation' do
      visit new_tag_path
      
      click_button 'Créer le tag'
      
      expect(page).to have_content('empêchent l\'enregistrement')
      expect(page).to have_content('Name doit être rempli(e)')
    end
    
    it 'allows editing a tag' do
      tag = create(:tag, organization: organization, name: 'Draft', color: 'bg-gray-100')
      
      visit tag_path(tag)
      click_link 'Modifier'
      
      fill_in 'Nom du tag', with: 'Brouillon'
      fill_in 'Description', with: 'Documents en cours de rédaction'
      find('label', text: 'bg-blue-100').click
      
      click_button 'Enregistrer'
      
      expect(page).to have_content('Tag mis à jour avec succès')
      expect(page).to have_content('Brouillon')
      expect(page).to have_content('Documents en cours de rédaction')
      expect(page).to have_css('.bg-blue-100')
    end
    
    it 'shows warning when editing tag with documents' do
      tag = create(:tag, organization: organization, name: 'Active')
      document = create(:document, space: space, uploaded_by: admin)
      document.tags << tag
      
      visit edit_tag_path(tag)
      
      expect(page).to have_content('Ce tag est utilisé par 1 document')
      expect(page).to have_content('Les modifications s\'appliqueront à tous ces documents')
    end
    
    it 'allows deleting a tag' do
      tag = create(:tag, organization: organization, name: 'Obsolete')
      
      visit tag_path(tag)
      
      accept_confirm do
        click_link 'Supprimer'
      end
      
      expect(page).to have_content('Tag supprimé avec succès')
      expect(page).to have_current_path(tags_path)
      expect(page).not_to have_content('Obsolete')
    end
    
    it 'shows edit and delete options in tag grid' do
      tag = create(:tag, organization: organization, name: 'Editable')
      
      visit tags_path
      
      within(find('.relative.flex', text: 'Editable')) do
        find('[data-action="click->dropdown#toggle"]').click
        
        expect(page).to have_link('Modifier')
        expect(page).to have_link('Supprimer')
      end
    end
  end
  
  describe 'Managing tags as regular user' do
    before do
      regular_user.add_permission!('tag:create')
      regular_user.add_permission!('tag:manage')
      login_as(regular_user, scope: :user)
    end
    
    it 'shows create button with permission' do
      visit tags_path
      
      expect(page).to have_link('Nouveau tag')
    end
    
    it 'allows creating tags with permission' do
      visit new_tag_path
      
      fill_in 'Nom du tag', with: 'Review'
      select 'Statut', from: 'Type de tag'
      
      click_button 'Créer le tag'
      
      expect(page).to have_content('Tag créé avec succès')
      expect(page).to have_content('Review')
    end
  end
  
  describe 'Tag autocomplete' do
    let!(:tag1) { create(:tag, organization: organization, name: 'Important') }
    let!(:tag2) { create(:tag, organization: organization, name: 'Improvement') }
    let!(:tag3) { create(:tag, organization: organization, name: 'Archive') }
    
    before do
      login_as(regular_user, scope: :user)
    end
    
    it 'returns matching tags' do
      visit tags_autocomplete_path(q: 'Imp')
      
      json = JSON.parse(page.body)
      expect(json.length).to eq(2)
      expect(json.map { |t| t['name'] }).to include('Important', 'Improvement')
      expect(json.map { |t| t['name'] }).not_to include('Archive')
    end
  end
  
  describe 'Tag usage in documents' do
    let!(:tag) { create(:tag, organization: organization, name: 'Validated', color: 'bg-green-100') }
    
    before do
      login_as(regular_user, scope: :user)
    end
    
    it 'shows documents with specific tag' do
      doc1 = create(:document, space: space, uploaded_by: regular_user, title: 'Report 2024')
      doc2 = create(:document, space: space, uploaded_by: regular_user, title: 'Analysis 2024')
      doc3 = create(:document, space: space, uploaded_by: regular_user, title: 'Draft 2024')
      
      doc1.tags << tag
      doc2.tags << tag
      
      visit tag_path(tag)
      
      expect(page).to have_content('2 documents')
      expect(page).to have_content('Report 2024')
      expect(page).to have_content('Analysis 2024')
      expect(page).not_to have_content('Draft 2024')
    end
    
    it 'allows navigating to document from tag view' do
      document = create(:document, space: space, uploaded_by: regular_user, title: 'Important Doc')
      document.tags << tag
      
      visit tag_path(tag)
      
      click_link 'Important Doc'
      
      expect(page).to have_current_path(ged_document_path(document))
      expect(page).to have_content('Important Doc')
    end
  end
  
  describe 'Empty states' do
    before do
      login_as(admin, scope: :user)
    end
    
    it 'shows empty state when no tags exist' do
      visit tags_path
      
      expect(page).to have_content('Aucun tag')
      expect(page).to have_content('Commencez par créer un nouveau tag')
      expect(page).to have_link('Nouveau tag')
    end
    
    it 'shows empty state when tag has no documents' do
      tag = create(:tag, organization: organization, name: 'Unused')
      
      visit tag_path(tag)
      
      expect(page).to have_content('Aucun document n\'utilise ce tag')
    end
  end
end