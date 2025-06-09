require 'rails_helper'

RSpec.describe 'Basket Management', type: :system do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let!(:document1) { create(:document, space: space, uploaded_by: user, title: 'First Document') }
  let!(:document2) { create(:document, space: space, uploaded_by: user, title: 'Second Document') }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
  end
  
  describe 'Basket creation' do
    it 'allows user to create a new basket' do
      visit baskets_path
      
      expect(page).to have_content('Mes bannettes')
      click_link 'Nouvelle bannette'
      
      fill_in 'Nom de la bannette', with: 'Documents importants'
      fill_in 'Description', with: 'Mes documents de travail prioritaires'
      find('label', text: 'bg-blue-100').click
      
      click_button 'Créer la bannette'
      
      expect(page).to have_content('Bannette créée avec succès')
      expect(page).to have_content('Documents importants')
      expect(page).to have_content('0 document')
    end
    
    it 'validates basket name presence' do
      visit new_basket_path
      
      click_button 'Créer la bannette'
      
      expect(page).to have_content('empêchent l\'enregistrement')
      expect(page).to have_content('Name doit être rempli(e)')
    end
  end
  
  describe 'Adding documents to basket' do
    let!(:basket) { create(:basket, user: user, name: 'Ma bannette') }
    
    it 'allows adding a document to basket from document view' do
      visit ged_document_path(document1)
      
      click_button 'Ajouter à la bannette'
      
      within('#add-to-basket-modal') do
        expect(page).to have_content('Ma bannette')
        expect(page).to have_content('0 document')
        
        click_button 'Ajouter'
      end
      
      expect(page).to have_content('Document ajouté à la bannette')
      
      visit basket_path(basket)
      expect(page).to have_content('First Document')
      expect(page).to have_content('1 document')
    end
    
    it 'prevents adding the same document twice' do
      basket.add_document(document1)
      
      visit ged_document_path(document1)
      click_button 'Ajouter à la bannette'
      
      within('#add-to-basket-modal') do
        click_button 'Ajouter'
      end
      
      visit basket_path(basket)
      expect(page).to have_content('1 document')
      expect(page).to have_css('.border', count: 1) # Only one document card
    end
    
    it 'shows option to create new basket when adding document' do
      visit ged_document_path(document1)
      
      click_button 'Ajouter à la bannette'
      
      within('#add-to-basket-modal') do
        expect(page).to have_link('Créer une nouvelle bannette')
      end
    end
  end
  
  describe 'Basket management' do
    let!(:basket) { create(:basket, user: user, name: 'Test Basket') }
    
    before do
      basket.add_document(document1)
      basket.add_document(document2)
    end
    
    it 'displays basket contents' do
      visit basket_path(basket)
      
      expect(page).to have_content('Test Basket')
      expect(page).to have_content('2 documents')
      expect(page).to have_content('First Document')
      expect(page).to have_content('Second Document')
    end
    
    it 'allows removing documents from basket' do
      visit basket_path(basket)
      
      within(first('.border')) do
        accept_confirm do
          find('a[href*="remove_document"]').click
        end
      end
      
      expect(page).to have_content('Document retiré de la bannette')
      expect(page).to have_content('1 document')
    end
    
    it 'allows editing basket' do
      visit basket_path(basket)
      
      click_link 'Modifier'
      
      fill_in 'Nom de la bannette', with: 'Updated Basket Name'
      fill_in 'Description', with: 'New description'
      
      click_button 'Enregistrer'
      
      expect(page).to have_content('Bannette mise à jour avec succès')
      expect(page).to have_content('Updated Basket Name')
      expect(page).to have_content('New description')
    end
    
    it 'allows deleting basket' do
      visit edit_basket_path(basket)
      
      accept_confirm do
        click_link 'Supprimer'
      end
      
      expect(page).to have_content('Bannette supprimée avec succès')
      expect(page).to have_current_path(baskets_path)
    end
  end
  
  describe 'Basket sharing' do
    let!(:basket) { create(:basket, user: user, name: 'Shared Basket') }
    
    before do
      basket.add_document(document1)
    end
    
    it 'allows sharing a basket' do
      visit basket_path(basket)
      
      click_link 'Partager'
      
      expect(page).to have_content('Lien de partage généré avec succès')
      expect(page).to have_content('Bannette partagée')
      expect(page).to have_content('Cette bannette est accessible via un lien de partage')
      expect(page).to have_button('Lien de partage')
    end
    
    it 'displays shared baskets to other users' do
      basket.generate_share_token!
      
      login_as(other_user, scope: :user)
      visit baskets_path
      
      expect(page).to have_content('Bannettes partagées')
      expect(page).to have_content('Shared Basket')
      expect(page).to have_content("Partagée par #{user.display_name}")
      expect(page).to have_content('1 document')
    end
  end
  
  describe 'Empty states' do
    it 'shows empty state when no baskets exist' do
      visit baskets_path
      
      expect(page).to have_content('Aucune bannette')
      expect(page).to have_content('Créez votre première bannette pour organiser vos documents')
      expect(page).to have_link('Nouvelle bannette')
    end
    
    it 'shows empty state when basket has no documents' do
      basket = create(:basket, user: user, name: 'Empty Basket')
      
      visit basket_path(basket)
      
      expect(page).to have_content('Aucun document')
      expect(page).to have_content('Cette bannette est vide')
      expect(page).to have_content('Ajoutez des documents depuis la vue document')
    end
  end
  
  describe 'Basket list view' do
    let!(:basket1) { create(:basket, user: user, name: 'Work Documents', color: 'bg-blue-100') }
    let!(:basket2) { create(:basket, user: user, name: 'Personal Files', color: 'bg-green-100') }
    
    before do
      basket1.add_document(document1)
      basket1.add_document(document2)
      basket2.add_document(document1)
    end
    
    it 'displays all user baskets with document counts' do
      visit baskets_path
      
      expect(page).to have_content('Work Documents')
      expect(page).to have_content('2 documents')
      
      expect(page).to have_content('Personal Files')
      expect(page).to have_content('1 document')
      
      # Check color indicators
      expect(page).to have_css('.bg-blue-100')
      expect(page).to have_css('.bg-green-100')
    end
    
    it 'provides dropdown actions for each basket' do
      visit baskets_path
      
      within(first('.relative.rounded-lg')) do
        find('[data-action="click->dropdown#toggle"]').click
        
        expect(page).to have_link('Voir')
        expect(page).to have_link('Modifier')
        expect(page).to have_link('Partager')
        expect(page).to have_link('Supprimer')
      end
    end
  end
end