require 'rails_helper'

RSpec.describe 'Document Viewing Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:folder) { create(:folder, organization: organization) }
  
  before do
    sign_in user
  end
  
  describe 'Document Preview' do
    context 'PDF documents' do
      let(:pdf_doc) { create(:document, :with_pdf_file, name: 'rapport_annuel.pdf', parent: folder) }
      
      it 'displays PDF inline with controls' do
        visit ged_document_path(pdf_doc)
        
        expect(page).to have_css('.document-viewer')
        expect(page).to have_css('.pdf-viewer-container')
        
        within '.pdf-toolbar' do
          expect(page).to have_button('Zoom +')
          expect(page).to have_button('Zoom -')
          expect(page).to have_button('Ajuster à la page')
          expect(page).to have_button('Rotation')
          expect(page).to have_field('Page', with: '1')
          expect(page).to have_content('/ 25') # Total pages
        end
        
        # Navigate pages
        fill_in 'Page', with: '10'
        page.send_keys(:enter)
        
        expect(page).to have_field('Page', with: '10')
        
        # Zoom controls
        click_button 'Zoom +'
        expect(page).to have_css('.pdf-container[data-zoom="125"]')
        
        click_button 'Ajuster à la page'
        expect(page).to have_css('.pdf-container[data-zoom="fit"]')
      end
      
      it 'supports fullscreen mode' do
        visit ged_document_path(pdf_doc)
        
        click_button 'Plein écran'
        
        expect(page).to have_css('.fullscreen-viewer')
        expect(page).to have_css('.fullscreen-controls')
        
        # ESC to exit
        page.send_keys(:escape)
        
        expect(page).not_to have_css('.fullscreen-viewer')
      end
    end
    
    context 'Image documents' do
      let(:image_doc) { create(:document, :with_image_file, name: 'plan_architecte.jpg', parent: folder) }
      
      it 'displays images with zoom and pan', js: true do
        visit ged_document_path(image_doc)
        
        expect(page).to have_css('.image-viewer-container')
        expect(page).to have_css('img.document-image')
        
        within '.image-toolbar' do
          expect(page).to have_button('Zoom +')
          expect(page).to have_button('Zoom -')
          expect(page).to have_button('Taille réelle')
          expect(page).to have_button('Ajuster')
          expect(page).to have_button('Rotation gauche')
          expect(page).to have_button('Rotation droite')
        end
        
        # Zoom with mouse wheel
        image = find('.document-image')
        image.hover
        page.execute_script("
          var e = new WheelEvent('wheel', { deltaY: -100, bubbles: true });
          arguments[0].dispatchEvent(e);
        ", image.native)
        
        expect(page).to have_css('.document-image[data-zoom="120"]')
        
        # Pan with drag
        image.drag_by(50, 50)
        
        # Rotation
        click_button 'Rotation droite'
        expect(page).to have_css('.document-image[data-rotation="90"]')
      end
      
      it 'shows image gallery for multiple images' do
        image_docs = create_list(:document, 5, :with_image_file, parent: folder)
        
        visit ged_document_path(image_docs.first)
        
        expect(page).to have_css('.image-gallery')
        expect(page).to have_css('.gallery-thumbnails')
        expect(page).to have_css('.thumbnail-item', count: 5)
        
        # Navigate with arrows
        click_button 'Image suivante'
        expect(page).to have_content(image_docs.second.name)
        
        # Click thumbnail
        within '.gallery-thumbnails' do
          all('.thumbnail-item')[3].click
        end
        
        expect(page).to have_content(image_docs[3].name)
        
        # Keyboard navigation
        page.send_keys(:arrow_left)
        expect(page).to have_content(image_docs[2].name)
      end
    end
    
    context 'Office documents' do
      let(:word_doc) { create(:document, :with_docx_file, name: 'contrat_client.docx', parent: folder) }
      let(:excel_doc) { create(:document, :with_xlsx_file, name: 'budget_2025.xlsx', parent: folder) }
      
      it 'displays Word documents with Office Online viewer' do
        visit ged_document_path(word_doc)
        
        expect(page).to have_css('.office-viewer-container')
        expect(page).to have_css('iframe.office-viewer')
        
        within '.office-toolbar' do
          expect(page).to have_link('Ouvrir dans Word Online')
          expect(page).to have_button('Télécharger')
          expect(page).to have_button('Imprimer')
        end
        
        # Check iframe src
        iframe = find('iframe.office-viewer')
        expect(iframe['src']).to include('view.officeapps.live.com')
        expect(iframe['src']).to include(CGI.escape(word_doc.file_url))
      end
      
      it 'displays Excel with preview and edit options' do
        visit ged_document_path(excel_doc)
        
        expect(page).to have_css('.excel-preview')
        expect(page).to have_content('Aperçu Excel')
        
        # Show data table preview
        within '.excel-preview-table' do
          expect(page).to have_css('table')
          expect(page).to have_css('th', text: 'Catégorie')
          expect(page).to have_css('td', text: '15,250€')
        end
        
        # Sheets navigation
        within '.excel-sheets' do
          expect(page).to have_button('Feuille 1')
          expect(page).to have_button('Feuille 2')
          
          click_button 'Feuille 2'
        end
        
        expect(page).to have_content('Détails par mois')
      end
    end
    
    context 'Video documents' do
      let(:video_doc) { create(:document, :with_video_file, name: 'presentation_projet.mp4', parent: folder) }
      
      it 'displays videos with player controls' do
        visit ged_document_path(video_doc)
        
        expect(page).to have_css('.video-player-container')
        expect(page).to have_css('video.document-video')
        
        video = find('video.document-video')
        expect(video['controls']).to eq('controls')
        expect(video['poster']).to be_present
        
        within '.video-info' do
          expect(page).to have_content('Durée: 5:32')
          expect(page).to have_content('Résolution: 1920x1080')
          expect(page).to have_content('Format: MP4')
        end
        
        # Custom controls
        within '.video-controls' do
          expect(page).to have_button('Play')
          expect(page).to have_css('.progress-bar')
          expect(page).to have_css('.volume-control')
          expect(page).to have_button('Plein écran')
          expect(page).to have_button('Vitesse')
        end
      end
    end
    
    context 'Text and code files' do
      let(:text_doc) { create(:document, :with_txt_file, name: 'notes_reunion.txt', parent: folder) }
      let(:code_doc) { create(:document, name: 'config.json', content_type: 'application/json', parent: folder) }
      
      it 'displays text files with syntax highlighting' do
        visit ged_document_path(code_doc)
        
        expect(page).to have_css('.code-viewer-container')
        expect(page).to have_css('pre.syntax-highlight')
        expect(page).to have_css('.line-numbers')
        
        within '.code-toolbar' do
          expect(page).to have_button('Copier')
          expect(page).to have_button('Rechercher')
          expect(page).to have_button('Word wrap')
          expect(page).to have_select('Thème', options: ['Light', 'Dark', 'Solarized'])
        end
        
        # Search functionality
        click_button 'Rechercher'
        fill_in 'search', with: 'config'
        
        expect(page).to have_css('.highlight-match', count: 3)
        expect(page).to have_content('3 résultats')
      end
    end
  end
  
  describe 'Document Information Panel' do
    let(:document) { create(:document, :with_pdf_file, parent: folder) }
    
    it 'displays comprehensive document information' do
      visit ged_document_path(document)
      
      within '.document-sidebar' do
        # Information tab
        click_link 'Informations'
        
        within '.document-info' do
          expect(page).to have_content('Type: PDF')
          expect(page).to have_content("Taille: #{number_to_human_size(document.file_size)}")
          expect(page).to have_content("Créé le: #{l(document.created_at)}")
          expect(page).to have_content("Modifié le: #{l(document.updated_at)}")
          expect(page).to have_content("Téléversé par: #{document.uploaded_by.name}")
          expect(page).to have_content("Organisation: #{document.organization.name}")
        end
        
        # Metadata tab
        click_link 'Métadonnées'
        
        within '.document-metadata' do
          expect(page).to have_content('Catégorie')
          expect(page).to have_content('Tags')
          expect(page).to have_content('Description')
          
          # Edit metadata inline
          click_button 'Modifier'
          
          fill_in 'Tags', with: 'important, confidentiel, 2025'
          fill_in 'Description', with: 'Document confidentiel pour la direction'
          
          click_button 'Enregistrer'
          
          expect(page).to have_content('Métadonnées mises à jour')
          expect(page).to have_content('important')
          expect(page).to have_content('confidentiel')
        end
        
        # Activity tab
        click_link 'Activité'
        
        within '.document-activity' do
          expect(page).to have_css('.activity-timeline')
          expect(page).to have_content('Document créé')
          expect(page).to have_content('Métadonnées modifiées')
          expect(page).to have_css('.activity-item', minimum: 2)
        end
        
        # Versions tab
        click_link 'Versions'
        
        within '.document-versions' do
          expect(page).to have_content('Version 1 (actuelle)')
          expect(page).to have_button('Télécharger v1')
          expect(page).to have_button('Nouvelle version')
        end
      end
    end
  end
  
  describe 'Document Actions from Viewer' do
    let(:document) { create(:document, :with_pdf_file, parent: folder) }
    
    it 'provides quick actions in viewer header' do
      visit ged_document_path(document)
      
      within '.document-header' do
        expect(page).to have_button('Télécharger')
        expect(page).to have_button('Partager')
        expect(page).to have_button('Imprimer')
        expect(page).to have_button('Éditer')
        expect(page).to have_button('Plus d\'actions')
        
        # Download action
        click_button 'Télécharger'
        expect(page.response_headers['Content-Disposition']).to include('attachment')
        
        visit ged_document_path(document) # Return to page
        
        # Share action
        click_button 'Partager'
        
        within '.share-modal' do
          fill_in 'Email', with: 'collegue@example.com'
          select 'Lecture seule', from: 'Permissions'
          fill_in 'Message', with: 'Voici le document demandé'
          
          click_button 'Envoyer'
        end
        
        expect(page).to have_content('Document partagé avec succès')
        
        # More actions dropdown
        click_button 'Plus d\'actions'
        
        within '.dropdown-menu' do
          expect(page).to have_link('Dupliquer')
          expect(page).to have_link('Déplacer')
          expect(page).to have_link('Archiver')
          expect(page).to have_link('Verrouiller')
          expect(page).to have_link('Demander validation')
          expect(page).to have_link('Générer lien public')
        end
      end
    end
    
    it 'supports keyboard shortcuts in viewer' do
      visit ged_document_path(document)
      
      # Show shortcuts help
      page.send_keys('?')
      
      within '.keyboard-shortcuts-modal' do
        expect(page).to have_content('Raccourcis clavier')
        expect(page).to have_content('D - Télécharger')
        expect(page).to have_content('P - Imprimer')
        expect(page).to have_content('F - Plein écran')
        expect(page).to have_content('← → - Navigation pages')
        expect(page).to have_content('+ - - Zoom')
      end
      
      find('.modal-close').click
      
      # Test shortcuts
      page.send_keys('f')
      expect(page).to have_css('.fullscreen-viewer')
      
      page.send_keys(:escape)
      expect(page).not_to have_css('.fullscreen-viewer')
    end
  end
  
  describe 'Document Comparison View' do
    let(:doc_v1) { create(:document, :with_pdf_file, name: 'contract_v1.pdf', parent: folder) }
    let(:doc_v2) { create(:document, :with_pdf_file, name: 'contract_v2.pdf', parent: folder, parent_version: doc_v1) }
    
    it 'compares two document versions side by side' do
      visit ged_document_path(doc_v2)
      
      click_link 'Comparer avec version précédente'
      
      expect(page).to have_css('.document-comparison-view')
      
      within '.comparison-container' do
        expect(page).to have_css('.left-document')
        expect(page).to have_css('.right-document')
        
        within '.left-document' do
          expect(page).to have_content('Version 1')
          expect(page).to have_css('.pdf-viewer-container')
        end
        
        within '.right-document' do
          expect(page).to have_content('Version 2 (actuelle)')
          expect(page).to have_css('.pdf-viewer-container')
        end
      end
      
      # Synchronized scrolling
      within '.comparison-controls' do
        expect(page).to have_css('input[type="checkbox"]#sync-scroll:checked')
        expect(page).to have_content('Défilement synchronisé')
        
        # Highlighting differences
        click_button 'Surligner différences'
        
        expect(page).to have_css('.difference-highlight')
        expect(page).to have_content('5 différences détectées')
      end
      
      # Navigation between differences
      within '.diff-navigation' do
        expect(page).to have_content('Différence 1/5')
        
        click_button 'Suivante'
        expect(page).to have_content('Différence 2/5')
        
        click_button 'Précédente'
        expect(page).to have_content('Différence 1/5')
      end
    end
  end
  
  describe 'Mobile Document Viewing', js: true do
    let(:document) { create(:document, :with_pdf_file, parent: folder) }
    
    it 'adapts viewer for mobile devices' do
      # Set mobile viewport
      page.driver.browser.manage.window.resize_to(375, 812)
      
      visit ged_document_path(document)
      
      expect(page).to have_css('.mobile-document-viewer')
      
      # Swipe gestures info
      expect(page).to have_css('.swipe-hint')
      expect(page).to have_content('Glissez pour naviguer')
      
      # Touch-friendly controls
      within '.mobile-controls' do
        expect(page).to have_css('.touch-button')
        expect(page).to have_button('◄') # Previous
        expect(page).to have_button('►') # Next
        expect(page).to have_button('⊕') # Zoom in
        expect(page).to have_button('⊖') # Zoom out
      end
      
      # Bottom sheet for actions
      find('.mobile-actions-trigger').click
      
      within '.bottom-sheet' do
        expect(page).to have_button('Télécharger')
        expect(page).to have_button('Partager')
        expect(page).to have_button('Envoyer par email')
        expect(page).to have_button('Ajouter aux favoris')
      end
      
      # Pinch to zoom gesture hint
      expect(page).to have_content('Pincez pour zoomer')
    end
  end
end