require 'rails_helper'

RSpec.describe "GED Upload Button Functionality", type: :system, js: true do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  
  before do
    sign_in user
  end
  
  describe "Dashboard upload buttons" do
    before do
      visit ged_dashboard_path
    end
    
    it "displays all upload buttons" do
      expect(page).to have_button("Nouvel Espace")
      expect(page).to have_button("Nouveau Dossier")
      expect(page).to have_button("Upload Document")
    end
    
    it "opens create space modal when clicking 'Nouvel Espace'" do
      click_button "Nouvel Espace"
      
      expect(page).to have_css("#createSpaceModal", visible: true)
      expect(page).to have_content("Créer un nouvel espace")
      expect(page).to have_field("space_name")
    end
    
    it "opens create folder modal when clicking 'Nouveau Dossier'" do
      click_button "Nouveau Dossier"
      
      expect(page).to have_css("#createFolderModal", visible: true)
      expect(page).to have_content("Créer un nouveau dossier")
    end
    
    it "opens upload modal when clicking 'Upload Document'" do
      click_button "Upload Document"
      
      expect(page).to have_css("#uploadModal", visible: true)
      expect(page).to have_content("Uploader un document")
    end
    
    it "closes modal when clicking cancel" do
      click_button "Nouvel Espace"
      expect(page).to have_css("#createSpaceModal", visible: true)
      
      within "#createSpaceModal" do
        click_button "Annuler"
      end
      
      expect(page).not_to have_css("#createSpaceModal", visible: true)
    end
    
    it "creates a new space through the modal" do
      click_button "Nouvel Espace"
      
      within "#createSpaceModal" do
        fill_in "space_name", with: "Test Space"
        fill_in "space_description", with: "Test Description"
        click_button "Créer"
      end
      
      expect(page).to have_content("Espace créé avec succès")
      expect(Space.last.name).to eq("Test Space")
    end
  end
  
  describe "Space page upload buttons" do
    before do
      visit ged_space_path(space)
    end
    
    it "displays upload buttons on space page" do
      expect(page).to have_button("Nouveau Dossier")
      expect(page).to have_button("Upload Document")
    end
    
    it "opens folder modal with space context" do
      click_button "Nouveau Dossier"
      
      expect(page).to have_css("#createFolderModal", visible: true)
      # Check if space is pre-selected
      within "#createFolderModal" do
        expect(find("#folder_space_id").value).to eq(space.id.to_s)
      end
    end
    
    it "opens upload modal with space context" do
      click_button "Upload Document"
      
      expect(page).to have_css("#uploadModal", visible: true)
      # Check if space is pre-selected
      within "#uploadModal" do
        expect(find("#document_space_id").value).to eq(space.id.to_s)
      end
    end
  end
  
  describe "JavaScript function availability" do
    before do
      visit ged_dashboard_path
    end
    
    it "has openModal function available" do
      expect(page.evaluate_script("typeof openModal")).to eq("function")
    end
    
    it "has closeModal function available" do
      expect(page.evaluate_script("typeof closeModal")).to eq("function")
    end
    
    it "can open modal via JavaScript" do
      page.execute_script("openModal('createSpaceModal')")
      expect(page).to have_css("#createSpaceModal", visible: true)
    end
    
    it "can close modal via JavaScript" do
      page.execute_script("openModal('createSpaceModal')")
      expect(page).to have_css("#createSpaceModal", visible: true)
      
      page.execute_script("closeModal('createSpaceModal')")
      expect(page).not_to have_css("#createSpaceModal", visible: true)
    end
  end
  
  describe "Modal form submission" do
    before do
      visit ged_dashboard_path
    end
    
    it "shows validation errors for empty space name" do
      click_button "Nouvel Espace"
      
      within "#createSpaceModal" do
        # Don't fill in the required name field
        click_button "Créer"
      end
      
      # Should show HTML5 validation or custom error
      expect(page).to have_css("#createSpaceModal", visible: true)
    end
    
    it "uploads a document through the modal" do
      space = create(:space, organization: organization, name: "Test Space")
      
      visit ged_dashboard_path
      click_button "Upload Document"
      
      within "#uploadModal" do
        attach_file "document_file", Rails.root.join("spec/fixtures/files/test.pdf")
        fill_in "document_title", with: "Test Document"
        select "Test Space", from: "document_space_id"
        click_button "Téléverser"
      end
      
      # Wait for modal to close
      expect(page).not_to have_css("#uploadModal", visible: true, wait: 5)
      
      # Verify document was created by checking if it appears in the list
      expect(page).to have_content("Test Document")
      
      # Verify in database
      expect(Document.last.title).to eq("Test Document")
      expect(Document.last.space).to eq(space)
    end
  end
  
  describe "Stimulus controller integration" do
    before do
      visit ged_dashboard_path
    end
    
    it "has GED controller attached" do
      expect(page).to have_css('[data-controller="ged"]')
    end
    
    it "form submissions are handled by Stimulus" do
      click_button "Nouvel Espace"
      
      # Check if form has proper data attributes or event listeners
      within "#createSpaceModal" do
        form = find("#createSpaceForm")
        # The form should prevent default submission
        expect(form[:onsubmit]).to be_nil # Should use addEventListener instead
      end
    end
  end
end