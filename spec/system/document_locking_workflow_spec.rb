require 'rails_helper'

RSpec.describe 'Document Locking Workflow', type: :system do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, organization: organization, role: 'admin') }
  let!(:document) { create(:document, space: space, uploaded_by: user, status: 'published', title: 'Test Document') }
  
  describe 'Locking a document' do
    before do
      login_as(user, scope: :user)
      visit ged_document_path(document)
    end
    
    it 'shows lock button for authorized user' do
      expect(page).to have_button('Verrouiller')
      expect(page).not_to have_button('Déverrouiller')
    end
    
    it 'allows locking document with reason' do
      click_button 'Verrouiller'
      
      within('#lock-document-modal') do
        fill_in 'Raison du verrouillage', with: 'Modification en cours'
        click_button 'Verrouiller'
      end
      
      expect(page).to have_content('Document verrouillé avec succès')
      expect(page).to have_content('Document verrouillé')
      expect(page).to have_content('Modification en cours')
      expect(page).to have_button('Déverrouiller')
      expect(page).not_to have_button('Verrouiller')
    end
    
    it 'allows scheduling automatic unlock' do
      unlock_time = 2.hours.from_now
      
      click_button 'Verrouiller'
      
      within('#lock-document-modal') do
        fill_in 'Raison du verrouillage', with: 'Révision temporaire'
        fill_in 'Déverrouillage automatique', with: unlock_time.strftime('%Y-%m-%dT%H:%M')
        click_button 'Verrouiller'
      end
      
      expect(page).to have_content('Document verrouillé avec succès')
      expect(page).to have_content('Déverrouillage prévu le')
    end
  end
  
  describe 'Viewing locked document' do
    before do
      document.lock_document!(user, reason: 'En cours de modification')
    end
    
    context 'as the user who locked it' do
      before do
        login_as(user, scope: :user)
        visit ged_document_path(document)
      end
      
      it 'shows lock information and unlock button' do
        expect(page).to have_content('Document verrouillé')
        expect(page).to have_content("Verrouillé par #{user.display_name}")
        expect(page).to have_content('En cours de modification')
        expect(page).to have_button('Déverrouiller')
      end
    end
    
    context 'as another user' do
      before do
        login_as(other_user, scope: :user)
        visit ged_document_path(document)
      end
      
      it 'shows lock information but no unlock button' do
        expect(page).to have_content('Document verrouillé')
        expect(page).to have_content("Verrouillé par #{user.display_name}")
        expect(page).not_to have_button('Déverrouiller')
        expect(page).not_to have_button('Verrouiller')
      end
    end
    
    context 'as admin' do
      before do
        login_as(admin_user, scope: :user)
        visit ged_document_path(document)
      end
      
      it 'shows unlock button for admin' do
        expect(page).to have_content('Document verrouillé')
        expect(page).to have_button('Déverrouiller')
      end
    end
  end
  
  describe 'Unlocking a document' do
    before do
      document.lock_document!(user, reason: 'Test lock')
      login_as(user, scope: :user)
      visit ged_document_path(document)
    end
    
    it 'unlocks the document' do
      click_button 'Déverrouiller'
      
      expect(page).to have_content('Document déverrouillé avec succès')
      expect(page).not_to have_content('Document verrouillé')
      expect(page).to have_button('Verrouiller')
      expect(page).not_to have_button('Déverrouiller')
    end
  end
  
  describe 'Lock expiration' do
    before do
      document.lock_document!(user, reason: 'Temporary lock', scheduled_unlock: 1.hour.ago)
      login_as(other_user, scope: :user)
      visit ged_document_path(document)
    end
    
    it 'shows expired lock information' do
      expect(page).to have_content('Document verrouillé')
      # In a real implementation, you might have a background job that automatically unlocks expired documents
      # For now, the UI just shows the scheduled unlock time
      expect(page).to have_content('Déverrouillage prévu le')
    end
  end
  
  describe 'Authorization checks' do
    context 'user without write permission' do
      before do
        # Create a user with only read permission
        document.authorize_user(other_user, 'read', granted_by: user)
        login_as(other_user, scope: :user)
        visit ged_document_path(document)
      end
      
      it 'does not show lock button' do
        expect(page).not_to have_button('Verrouiller')
      end
    end
    
    context 'user with write permission' do
      before do
        document.authorize_user(other_user, 'write', granted_by: user)
        login_as(other_user, scope: :user)
        visit ged_document_path(document)
      end
      
      it 'shows lock button' do
        expect(page).to have_button('Verrouiller')
      end
    end
  end
end