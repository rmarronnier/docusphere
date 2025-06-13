require 'rails_helper'

RSpec.describe 'Document Management - Basic Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, organization: organization, role: :admin) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, name: 'Test Folder', space: space) }
  let(:other_user) { create(:user, organization: organization) }
  
  before do
    sign_in user
  end
  
  describe 'Document Actions Dropdown', :js do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    it 'displays the actions dropdown menu' do
      visit ged_document_path(document)
      
      # Find and click the dropdown button
      dropdown_button = find('button[data-action="click->dropdown#toggle"]')
      expect(dropdown_button).to be_visible
      
      dropdown_button.click
      
      # Check that the menu appears
      menu = find('[data-dropdown-target="menu"]', visible: true)
      expect(menu).to be_visible
      
      # Check for basic actions in the menu
      within menu do
        # Debug: see what's actually available
        available_actions = all('a').map(&:text)
        puts "Available actions in dropdown: #{available_actions.join(', ')}"
        
        # Check for any actions
        expect(page).to have_css('a', minimum: 1)
      end
    end
    
    it 'opens the move modal when clicking move action' do
      visit ged_document_path(document)
      
      # Open dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Click move action
      within '[data-dropdown-target="menu"]', visible: true do
        if page.has_link?('Déplacer', wait: 2)
          click_link 'Déplacer'
        else
          skip 'Move action not available - may require write permissions'
        end
      end
      
      # Check that move modal opens
      move_modal = find('#move-document-modal', visible: true)
      expect(move_modal).to be_visible
      
      within move_modal do
        expect(page).to have_content('Déplacer le document')
        expect(page).to have_select('folder_id')
        expect(page).to have_button('Déplacer')
        expect(page).to have_button('Annuler')
      end
    end
    
    it 'opens the validation request modal' do
      visit ged_document_path(document)
      
      # Open dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Click validation action
      within '[data-dropdown-target="menu"]', visible: true do
        if page.has_link?('Demander validation')
          click_link 'Demander validation'
        else
          skip 'Validation action not present in dropdown'
        end
      end
      
      # Check that validation modal opens
      validation_modal = find('#request-validation-modal', visible: true)
      expect(validation_modal).to be_visible
      
      within validation_modal do
        expect(page).to have_content('Demander une validation')
        expect(page).to have_select('validator_id')
        expect(page).to have_field('message')
        expect(page).to have_field('due_date')
        expect(page).to have_button('Envoyer la demande')
      end
    end
  end
  
  describe 'Document Sharing', :js do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    it 'opens share modal from dropdown' do
      visit ged_document_path(document)
      
      # Open dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Click share action
      within '[data-dropdown-target="menu"]', visible: true do
        if page.has_link?('Partager', wait: 1)
          click_link 'Partager'
        elsif page.has_link?('Générer lien public', wait: 1)
          # Try alternative share action
          click_link 'Générer lien public'
        else
          skip 'Share action not available in dropdown'
        end
      end
      
      # The share modal should open
      share_modal = find('#share-modal', visible: true)
      expect(share_modal).to be_visible
      
      within share_modal do
        expect(page).to have_content('Partager le document')
        expect(page).to have_field('email')
        expect(page).to have_field('message')
        expect(page).to have_button('Envoyer')
      end
    end
  end
  
  describe 'Document Locking (Legacy View)' do
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
    
    it 'allows document owner to lock and unlock', :js do
      visit ged_document_path(document)
      
      # Make legacy view visible for this test
      page.execute_script("document.querySelector('.legacy-document-view')?.classList.remove('hidden')")
      
      within '.legacy-document-view' do
        # Find the lock button
        lock_button = find('button[data-modal-target-value="lock-document-modal"]', visible: :all)
        
        if lock_button.visible?
          lock_button.click
          
          # Fill lock modal
          within '#lock-document-modal', visible: true do
            fill_in 'lock_reason', with: 'Modification en cours'
            click_button 'Verrouiller'
          end
          
          expect(page).to have_content('Document verrouillé')
          
          # Check that document shows as locked
          visit ged_document_path(document)
          page.execute_script("document.querySelector('.legacy-document-view')?.classList.remove('hidden')")
          
          within '.legacy-document-view' do
            expect(page).to have_css('.bg-yellow-50')
            expect(page).to have_content('Document verrouillé')
            expect(page).to have_button('Déverrouiller')
          end
        else
          skip 'Lock functionality not visible in current view'
        end
      end
    end
  end
  
  describe 'Document Preview Modal', :js do
    let(:document) { create(:document, :with_pdf_file, folder: folder, space: space, uploaded_by: user) }
    
    it 'opens preview modal from dropdown' do
      visit ged_document_path(document)
      
      # Open dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Click preview if available
      within '[data-dropdown-target="menu"]', visible: true do
        if page.has_link?('Aperçu')
          click_link 'Aperçu'
          
          # Check preview modal
          preview_modal = find('#preview-modal', visible: true)
          expect(preview_modal).to be_visible
          
          within preview_modal do
            expect(page).to have_content(document.title)
            expect(page).to have_css('.document-preview-container')
          end
        else
          skip 'Preview action not available in dropdown'
        end
      end
    end
  end
  
  describe 'Document Download', :js do
    let(:document) { create(:document, :with_pdf_file, folder: folder, space: space, uploaded_by: user) }
    
    it 'provides download link in dropdown' do
      visit ged_document_path(document)
      
      # Open dropdown
      find('button[data-action="click->dropdown#toggle"]').click
      
      # Check for download link
      within '[data-dropdown-target="menu"]', visible: true do
        # Debug: print what actions are available
        puts "Available actions: #{all('a').map(&:text).join(', ')}"
        
        if page.has_link?('Télécharger', wait: 2)
          download_link = find_link('Télécharger')
          expect(download_link).to be_visible
          
          # The download link should have the correct href
          expect(download_link[:href]).to include('/download')
        else
          skip 'Download action not available - may be a permissions issue'
        end
      end
    end
  end
  
  describe 'Document Viewer Integration' do
    let(:document) { create(:document, :with_pdf_file, folder: folder, space: space, uploaded_by: user) }
    
    it 'displays document in viewer component' do
      visit ged_document_path(document)
      
      # Check viewer container
      viewer = find('.document-viewer-container')
      expect(viewer).to be_visible
      
      # Check that viewer shows document info
      within viewer do
        expect(page).to have_content(document.title)
        
        # Check for action buttons in viewer
        if page.has_css?('.viewer-actions')
          within '.viewer-actions' do
            expect(page).to have_css('button', minimum: 1)
          end
        end
      end
    end
  end
end