require 'rails_helper'

RSpec.describe "Document Upload Workflow", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  
  before do
    # Login
    login_as(user, scope: :user)
    
    # Ensure we have a space
    space
  end
  
  describe "complete upload workflow", js: true do
    it "allows user to upload a document from dashboard to viewing it" do
      # 1. Aller au dashboard
      visit ged_dashboard_path
      expect(page).to have_content("Gestion Électronique de Documents")
      
      # 2. Cliquer sur le bouton d'upload
      click_button "Upload Document"
      
      # 3. Attendre que la modale s'ouvre
      expect(page).to have_css('#uploadModal:not(.hidden)', wait: 2)
      within '#uploadModal' do
        expect(page).to have_content("Télécharger un document")
      end
      
      # 4. Remplir le formulaire
      within '#uploadForm' do
        fill_in 'document_title', with: 'Mon Document Test'
        fill_in 'document_description', with: 'Description de test'
        select space.name, from: 'document_space_id'
        
        # Attacher un fichier
        attach_file 'document_file', Rails.root.join('spec/fixtures/test_document.pdf')
      end
      
      # 5. Soumettre le formulaire
      within '#uploadModal' do
        click_button 'Télécharger'
      end
      
      # 6. Vérifier la redirection et le message de succès
      expect(page).to have_current_path(/\/ged\/documents\/\d+/)
      expect(page).to have_content('Document uploadé avec succès')
      
      # 7. Vérifier que le document est affiché
      expect(page).to have_content('Mon Document Test')
      expect(page).to have_content('Description de test')
      expect(page).to have_content('test_document.pdf')
      
      # 8. Vérifier le statut de traitement
      within '.processing-status' do
        expect(page).to have_content('En cours de traitement')
      end
      
      # 9. Attendre que le traitement se termine (simulé)
      # Dans un vrai test, on pourrait utiliser Sidekiq::Testing.inline!
      sleep 2
      page.refresh
      
      within '.processing-status' do
        expect(page).to have_content('Traitement terminé')
      end
    end
    
    it "shows validation errors for invalid form submission" do
      visit ged_dashboard_path
      
      click_button "Upload Document"
      expect(page).to have_css('#uploadModal:not(.hidden)')
      
      # Soumettre sans remplir les champs obligatoires
      within '#uploadModal' do
        click_button 'Télécharger'
      end
      
      # Vérifier les erreurs
      within '#uploadErrors' do
        expect(page).to have_content("Le titre doit être rempli")
        expect(page).to have_content("Le fichier doit être rempli")
      end
      
      # La modale doit rester ouverte
      expect(page).to have_css('#uploadModal:not(.hidden)')
    end
  end
  
  describe "drag and drop upload", js: true do
    it "allows file upload via drag and drop" do
      visit ged_dashboard_path
      
      # Simuler le drag and drop
      drop_zone = find('.drop-zone')
      
      # Trigger drag events
      drop_zone.execute_script("
        var e = new Event('dragenter', { bubbles: true });
        this.dispatchEvent(e);
      ")
      
      expect(drop_zone).to have_css('.drag-over')
      
      # Simuler le drop d'un fichier
      drop_file(drop_zone, Rails.root.join('spec/fixtures/test_document.pdf'))
      
      # Vérifier que le formulaire est pré-rempli
      within '#uploadModal' do
        expect(find('#document_title').value).to eq('test_document')
        expect(page).to have_content('test_document.pdf')
      end
    end
  end
  
  private
  
  def drop_file(drop_zone, file_path)
    # Helper pour simuler le drag & drop
    page.execute_script <<-JS
      var fileInput = document.createElement('input');
      fileInput.type = 'file';
      fileInput.id = 'temp-file-input';
      document.body.appendChild(fileInput);
    JS
    
    attach_file('temp-file-input', file_path)
    
    page.execute_script <<-JS
      var fileInput = document.getElementById('temp-file-input');
      var file = fileInput.files[0];
      var dt = new DataTransfer();
      dt.items.add(file);
      
      var dropEvent = new DragEvent('drop', {
        bubbles: true,
        dataTransfer: dt
      });
      
      arguments[0].dispatchEvent(dropEvent);
      fileInput.remove();
    JS
  end
end