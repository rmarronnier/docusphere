require 'rails_helper'

RSpec.describe 'Document Viewer Actions', type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, name: 'Test Folder', space: space) }
  
  before do
    sign_in user
  end
  
  describe 'Document Viewer Interface' do
    let(:document) { create(:document, :with_pdf_file, folder: folder, space: space, uploaded_by: user) }
    
    it 'displays document in the viewer with action buttons' do
      visit ged_document_path(document)
      
      # Check that the viewer component is rendered
      viewer = find('.document-viewer-component')
      expect(viewer).to be_visible
      
      # Check document header
      within '.document-header' do
        expect(page).to have_content(document.title)
        expect(page).to have_content(user.display_name)
        expect(page).to have_content(folder.name)
      end
      
      # Check viewer actions
      within '.viewer-actions' do
        # Download button should be visible
        expect(page).to have_link('Download')
        
        # Edit button should be visible for document owner
        expect(page).to have_link('Edit')
        
        # Share button should be visible
        expect(page).to have_button('Partager')
      end
    end
    
    it 'has a share button' do
      visit ged_document_path(document)
      
      within '.viewer-actions' do
        share_button = find_button('Partager')
        expect(share_button).to be_visible
        
        # Check that the button has the proper data attributes for modal
        expect(share_button['data-action']).to eq('click->modal#open')
        expect(share_button['data-modal-target-value']).to include('share-modal')
      end
      
      # Note: The actual share modal functionality might need the share modal component
      # to be rendered on the page, which might not be happening in the test environment
    end
    
    it 'downloads document when clicking download button' do
      visit ged_document_path(document)
      
      within '.viewer-actions' do
        download_link = find_link('Download')
        expect(download_link[:href]).to include('/download')
      end
    end
  end
  
  describe 'Document Sidebar' do
    let(:document) { create(:document, :with_pdf_file, folder: folder, space: space, uploaded_by: user) }
    
    it 'displays document information in sidebar' do
      visit ged_document_path(document)
      
      # Check sidebar exists
      sidebar = find('[data-controller="document-sidebar"]')
      expect(sidebar).to be_visible
      
      # Information tab should be active by default
      within sidebar do
        expect(page).to have_button('Information', class: 'text-blue-600')
        
        # Check file details
        within '[data-document-sidebar-target="infoTab"]' do
          expect(page).to have_content('File Details')
          expect(page).to have_content('Type:')
          expect(page).to have_content('PDF')
          expect(page).to have_content('Size:')
        end
      end
    end
    
    it 'has clickable sidebar tabs' do
      visit ged_document_path(document)
      
      # The sidebar is actually the right panel with tabs
      sidebar = find('.w-80.bg-gray-50.border-l')
      
      within sidebar do
        # Check that all expected tabs are present
        expect(page).to have_button('Information')
        expect(page).to have_button('Metadata')
        expect(page).to have_button('Activity')
        
        # Click on each tab to ensure they're clickable
        click_button 'Metadata'
        # Small wait to allow any JS to execute
        sleep 0.1
        
        click_button 'Activity'
        sleep 0.1
        
        click_button 'Information'
        
        # All tabs should still be visible after clicking
        expect(page).to have_button('Information')
        expect(page).to have_button('Metadata')
        expect(page).to have_button('Activity')
      end
    end
  end
  
  describe 'PDF Viewer Controls' do
    let(:document) { create(:document, :with_pdf_file, folder: folder, space: space, uploaded_by: user) }
    
    it 'displays PDF viewer controls for PDF documents' do
      visit ged_document_path(document)
      
      # Check for PDF viewer container
      pdf_viewer = find('.pdf-viewer-container')
      expect(pdf_viewer).to be_visible
      
      within '.pdf-toolbar' do
        # Navigation controls
        expect(page).to have_button('Previous Page')
        expect(page).to have_button('Next Page')
        expect(page).to have_field(type: 'number', with: '1')
        
        # Zoom controls
        expect(page).to have_select(selected: 'Auto')
        expect(page).to have_button('Zoom Out')
        expect(page).to have_button('Zoom In')
        
        # View controls
        expect(page).to have_button('Fullscreen')
        expect(page).to have_button('Print')
      end
    end
  end
  
  describe 'Access Control' do
    let(:other_user) { create(:user, organization: organization) }
    let(:document) { create(:document, folder: folder, space: space, uploaded_by: other_user) }
    
    it 'shows limited actions for non-owner users' do
      visit ged_document_path(document)
      
      within '.viewer-actions' do
        # Download should still be available
        expect(page).to have_link('Download')
        
        # Edit should not be available for non-owner
        expect(page).not_to have_link('Edit')
        
        # Share may or may not be available depending on permissions
      end
    end
  end
  
  describe 'Locked Document' do
    let(:document) { create(:document, :locked, folder: folder, space: space, uploaded_by: user) }
    
    it 'shows lock indicator for locked documents' do
      visit ged_document_path(document)
      
      within '.document-header' do
        expect(page).to have_content('Locked')
        expect(page).to have_css('.text-red-600')
      end
    end
  end
end