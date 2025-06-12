require 'rails_helper'

RSpec.describe 'Document Upload Actions', type: :system do
  let(:organization) { create(:organization, name: 'Test Org') }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, name: 'Espace Principal', organization: organization) }
  let(:folder) { create(:folder, name: 'Documents 2025', space: space) }
  
  before do
    sign_in user
  end
  
  describe 'Single Document Upload' do
    it 'uploads document via button' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/sample.pdf')
        fill_in 'Titre', with: 'sample.pdf'
        fill_in 'Description', with: 'Document de test'
        select 'Contrat', from: 'Catégorie'
        fill_in 'Tags', with: 'test, upload, pdf'
        select 'Espace Principal', from: 'Espace'
        
        click_button 'Téléverser'
      end
      
      # Attendre la soumission et vérifier si la modale se ferme
      expect(page).to have_content('Document téléversé avec succès', wait: 5).or have_content('sample.pdf')
    end
    
    it 'shows upload progress for large files' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/large_document.pdf')
        
        click_button 'Téléverser'
        
        expect(page).to have_css('.upload-progress')
        expect(page).to have_css('.progress-bar')
        expect(page).to have_content('Téléversement en cours...')
      end
      
      # Wait for upload to complete
      expect(page).to have_content('Document téléversé avec succès', wait: 10)
    end
  end
  
  describe 'Multiple Document Upload' do
    it 'uploads multiple documents via drag and drop', js: true do
      visit ged_folder_path(folder)
      
      # Simulate drag and drop
      drop_zone = find('.document-grid')
      
      # Trigger drag enter
      drop_zone.execute_script("
        var e = new DragEvent('dragenter', { bubbles: true });
        this.dispatchEvent(e);
      ")
      
      expect(page).to have_css('.drop-zone-active')
      expect(page).to have_content('Déposez vos fichiers ici')
      
      # Simulate file drop
      drop_files([
        Rails.root.join('spec/fixtures/files/doc1.pdf'),
        Rails.root.join('spec/fixtures/files/doc2.docx'),
        Rails.root.join('spec/fixtures/files/image.jpg')
      ])
      
      # Batch upload modal
      within '.batch-upload-modal' do
        expect(page).to have_content('3 fichiers à téléverser')
        
        # Set metadata for all
        select 'Documents techniques', from: 'Catégorie pour tous'
        fill_in 'Tags pour tous', with: 'batch, import'
        
        # Individual metadata
        within '#file_0' do
          fill_in 'Description', with: 'Premier document'
        end
        
        within '#file_1' do
          fill_in 'Description', with: 'Deuxième document'
          select 'Contrat', from: 'Catégorie'
        end
        
        click_button 'Téléverser tout'
      end
      
      # Progress tracking
      expect(page).to have_css('.batch-upload-progress')
      expect(page).to have_content('1/3')
      expect(page).to have_content('2/3')
      expect(page).to have_content('3/3')
      
      expect(page).to have_content('3 documents téléversés avec succès')
      expect(page).to have_css('.document-card', count: 3)
    end
    
    it 'handles upload errors gracefully' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        # Try to upload unsupported file
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/malicious.exe')
        
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Type de fichier non autorisé')
      expect(page).to have_css('.alert-danger')
      expect(page).not_to have_content('malicious.exe')
    end
  end
  
  describe 'Upload from External Sources' do
    it 'imports from cloud storage' do
      visit ged_folder_path(folder)
      
      click_button 'Importer depuis'
      click_link 'Google Drive'
      
      within '.cloud-import-modal' do
        # Simulate OAuth flow
        click_button 'Connecter Google Drive'
        
        # Mock successful connection
        expect(page).to have_content('Connecté à Google Drive')
        
        # Select files
        within '.cloud-file-browser' do
          check 'Presentation Q4.pptx'
          check 'Budget 2025.xlsx'
          check 'Contract Draft.docx'
        end
        
        click_button 'Importer sélection'
      end
      
      expect(page).to have_content('3 fichiers importés depuis Google Drive')
      expect(page).to have_content('Presentation Q4.pptx')
    end
    
    it 'uploads via email attachment forward' do
      visit ged_folder_path(folder)
      
      click_link 'Email vers GED'
      
      within '.email-upload-info' do
        expect(page).to have_content('upload@docusphere.com')
        expect(page).to have_content('Votre code unique')
        
        # Copy email address
        click_button 'Copier l\'adresse'
        
        expect(page).to have_content('Adresse copiée')
      end
      
      # Simulate email received
      EmailUploadJob.perform_now(
        to: 'upload+ABC123@docusphere.com',
        from: user.email,
        subject: 'Documents pour projet Alpha',
        attachments: ['rapport.pdf', 'annexe.docx']
      )
      
      # Refresh page
      visit current_path
      
      expect(page).to have_content('2 nouveaux documents reçus par email')
      expect(page).to have_content('rapport.pdf')
      expect(page).to have_content('Documents pour projet Alpha')
    end
  end
  
  describe 'Upload with Processing' do
    it 'processes and extracts metadata from uploaded document' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/invoice_2025.pdf')
        check 'Extraction automatique des métadonnées'
        
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Document en cours de traitement...')
      
      # Wait for processing
      within '.document-card', text: 'invoice_2025.pdf' do
        expect(page).to have_css('.processing-indicator')
      end
      
      # After processing
      expect(page).to have_content('Traitement terminé')
      
      click_link 'invoice_2025.pdf'
      
      # Check extracted metadata
      within '.document-metadata' do
        expect(page).to have_content('Type: Facture')
        expect(page).to have_content('Montant: 15,250€')
        expect(page).to have_content('Date: 15/12/2025')
        expect(page).to have_content('Fournisseur: ACME Corp')
      end
    end
    
    it 'generates thumbnails for images and PDFs' do
      visit ged_folder_path(folder)
      
      # Upload image
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/architecture_plan.jpg')
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Document téléversé avec succès')
      
      # Check thumbnail generation
      within '.document-card', text: 'architecture_plan.jpg' do
        expect(page).to have_css('img.document-thumbnail')
        thumbnail = find('img.document-thumbnail')
        expect(thumbnail['src']).to include('thumb_')
      end
      
      # Upload PDF
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/blueprint.pdf')
        click_button 'Téléverser'
      end
      
      # Check PDF thumbnail
      within '.document-card', text: 'blueprint.pdf' do
        expect(page).to have_css('img.document-thumbnail')
        expect(page).not_to have_css('.file-icon') # Real thumbnail, not icon
      end
    end
  end
  
  describe 'Upload with Version Control' do
    let!(:existing_doc) { create(:document, name: 'contract_v1.pdf', parent: folder) }
    
    it 'creates new version when uploading same filename' do
      visit ged_document_path(existing_doc)
      
      expect(page).to have_content('Version 1')
      
      click_button 'Nouvelle version'
      
      within '.version-upload-modal' do
        attach_file 'version[file]', Rails.root.join('spec/fixtures/files/contract_v2.pdf')
        fill_in 'Commentaire de version', with: 'Mise à jour des conditions générales'
        check 'Version majeure'
        
        click_button 'Créer version'
      end
      
      expect(page).to have_content('Version 2 créée avec succès')
      expect(page).to have_content('Version actuelle: 2')
      
      # Check version history
      click_link 'Historique des versions'
      
      within '.version-timeline' do
        expect(page).to have_content('Version 2')
        expect(page).to have_content('Mise à jour des conditions générales')
        expect(page).to have_content('Version 1')
        expect(page).to have_css('.version-item', count: 2)
      end
    end
    
    it 'detects duplicate upload and suggests version' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/contract_v1.pdf')
        click_button 'Téléverser'
      end
      
      # Duplicate detection
      within '.duplicate-detection-modal' do
        expect(page).to have_content('Document similaire détecté')
        expect(page).to have_content('contract_v1.pdf existe déjà')
        
        # Options
        expect(page).to have_button('Créer une nouvelle version')
        expect(page).to have_button('Téléverser comme nouveau document')
        expect(page).to have_button('Annuler')
        
        click_button 'Créer une nouvelle version'
      end
      
      expect(page).to have_content('Version 2 créée')
      expect(page).to have_current_path(ged_document_path(existing_doc))
    end
  end
  
  describe 'Upload Security' do
    it 'scans uploaded files for viruses' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/safe_document.pdf')
        click_button 'Téléverser'
      end
      
      # Show scanning status
      expect(page).to have_content('Analyse antivirus en cours...')
      expect(page).to have_css('.virus-scan-indicator')
      
      # After scan
      expect(page).to have_content('Document vérifié et sécurisé')
      expect(page).to have_css('.security-badge', text: 'Scanné')
    end
    
    it 'quarantines infected files' do
      # Mock virus detection
      allow_any_instance_of(VirusScanService).to receive(:scan).and_return({
        clean: false,
        virus_name: 'EICAR-Test-File'
      })
      
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/infected.pdf')
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Menace détectée')
      expect(page).to have_content('EICAR-Test-File')
      expect(page).to have_content('Le fichier a été mis en quarantaine')
      expect(page).not_to have_content('infected.pdf')
      
      # Admin notification sent
      expect(ActionMailer::Base.deliveries.last.subject).to include('Virus détecté')
    end
  end
  
  private
  
  def drop_files(file_paths)
    # Helper to simulate file drop
    js_script = <<~JS
      var dt = new DataTransfer();
      #{file_paths.map { |path| "dt.items.add(new File([''], '#{File.basename(path)}'));" }.join("\n")}
      
      var e = new DragEvent('drop', {
        bubbles: true,
        dataTransfer: dt
      });
      
      document.querySelector('.document-grid').dispatchEvent(e);
    JS
    
    page.execute_script(js_script)
  end
end