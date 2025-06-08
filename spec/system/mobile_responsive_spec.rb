require 'rails_helper'

RSpec.describe "Mobile Responsive Design", type: :system do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:document) { create(:document, 
    title: "Document Mobile Test",
    space: space,
    user: user
  )}
  
  before do
    login_as(user, scope: :user)
  end
  
  # Helper pour définir différentes tailles d'écran
  def set_viewport_size(device)
    case device
    when :mobile
      page.driver.browser.manage.window.resize_to(375, 812) # iPhone X
    when :tablet
      page.driver.browser.manage.window.resize_to(768, 1024) # iPad
    when :desktop
      page.driver.browser.manage.window.resize_to(1920, 1080) # Full HD
    end
  end
  
  describe "mobile navigation", js: true do
    before { set_viewport_size(:mobile) }
    
    it "shows hamburger menu on mobile" do
      visit root_path
      
      # Le menu hamburger doit être visible
      expect(page).to have_css('.mobile-menu-toggle')
      expect(page).not_to have_css('.desktop-nav')
      
      # Ouvrir le menu mobile
      find('.mobile-menu-toggle').click
      
      # Le menu doit glisser depuis le côté
      expect(page).to have_css('.mobile-menu.active')
      
      within '.mobile-menu' do
        expect(page).to have_link("Tableau de bord")
        expect(page).to have_link("Documents")
        expect(page).to have_link("Espaces")
        expect(page).to have_link("Mon profil")
        expect(page).to have_link("Déconnexion")
      end
      
      # Fermer en cliquant sur l'overlay
      find('.mobile-menu-overlay').click
      expect(page).not_to have_css('.mobile-menu.active')
    end
    
    it "adapts search interface for mobile" do
      visit root_path
      
      # La barre de recherche doit être compacte
      expect(page).to have_css('.mobile-search-toggle')
      
      # Cliquer pour étendre la recherche
      find('.mobile-search-toggle').click
      
      expect(page).to have_css('.mobile-search-overlay')
      
      within '.mobile-search-overlay' do
        fill_in "search", with: "test"
        
        # Les suggestions doivent être en plein écran
        expect(page).to have_css('.mobile-search-suggestions')
      end
      
      # Bouton pour fermer la recherche
      find('.close-mobile-search').click
      expect(page).not_to have_css('.mobile-search-overlay')
    end
    
    it "handles swipe gestures" do
      visit ged_space_path(space)
      
      # Simuler un swipe pour ouvrir le menu
      page.execute_script <<-JS
        var touchstart = new TouchEvent('touchstart', {
          touches: [{ clientX: 10, clientY: 100 }]
        });
        var touchend = new TouchEvent('touchend', {
          changedTouches: [{ clientX: 200, clientY: 100 }]
        });
        document.body.dispatchEvent(touchstart);
        document.body.dispatchEvent(touchend);
      JS
      
      expect(page).to have_css('.mobile-menu.active')
      
      # Swipe pour fermer
      page.execute_script <<-JS
        var touchstart = new TouchEvent('touchstart', {
          touches: [{ clientX: 300, clientY: 100 }]
        });
        var touchend = new TouchEvent('touchend', {
          changedTouches: [{ clientX: 50, clientY: 100 }]
        });
        document.querySelector('.mobile-menu').dispatchEvent(touchstart);
        document.querySelector('.mobile-menu').dispatchEvent(touchend);
      JS
      
      expect(page).not_to have_css('.mobile-menu.active')
    end
  end
  
  describe "responsive layouts", js: true do
    it "adjusts grid layouts for different screen sizes" do
      # Créer plusieurs documents
      5.times { |i| create(:document, title: "Doc #{i}", space: space) }
      
      visit ged_space_path(space)
      
      # Desktop: grille 3 colonnes
      set_viewport_size(:desktop)
      expect(page).to have_css('.grid.grid-cols-3')
      
      # Tablet: grille 2 colonnes
      set_viewport_size(:tablet)
      expect(page).to have_css('.grid.grid-cols-2')
      
      # Mobile: une seule colonne
      set_viewport_size(:mobile)
      expect(page).to have_css('.grid.grid-cols-1')
    end
    
    it "shows optimized document cards on mobile" do
      set_viewport_size(:mobile)
      visit ged_space_path(space)
      
      within '.document-card' do
        # Version mobile compacte
        expect(page).to have_css('.mobile-card-layout')
        
        # Actions dans un menu déroulant au lieu de boutons
        expect(page).not_to have_button("Télécharger")
        expect(page).to have_css('.card-actions-menu')
        
        find('.card-actions-menu').click
        expect(page).to have_link("Télécharger")
        expect(page).to have_link("Partager")
      end
    end
    
    it "adapts tables to mobile view" do
      # Créer plusieurs documents pour avoir un tableau
      10.times { |i| create(:document, title: "Document #{i}", space: space) }
      
      visit ged_space_path(space)
      
      # Basculer en vue tableau
      click_button "Vue tableau"
      
      # Desktop: tableau normal
      set_viewport_size(:desktop)
      expect(page).to have_css('table.document-table')
      expect(page).to have_css('thead')
      
      # Mobile: cartes au lieu de tableau
      set_viewport_size(:mobile)
      expect(page).not_to have_css('table.document-table')
      expect(page).to have_css('.mobile-table-cards')
      
      within first('.mobile-table-card') do
        expect(page).to have_content("Titre:")
        expect(page).to have_content("Date:")
        expect(page).to have_content("Taille:")
      end
    end
  end
  
  describe "mobile forms and modals", js: true do
    before { set_viewport_size(:mobile) }
    
    it "displays full-screen modals on mobile" do
      visit ged_dashboard_path
      
      click_button "Nouveau Document"
      
      # La modale doit être en plein écran sur mobile
      expect(page).to have_css('.modal.mobile-fullscreen')
      
      within '.modal' do
        # Header fixe avec bouton retour
        expect(page).to have_css('.mobile-modal-header')
        expect(page).to have_button("Retour")
        
        # Contenu scrollable
        expect(page).to have_css('.mobile-modal-content')
        
        # Actions en bas fixe
        expect(page).to have_css('.mobile-modal-footer')
      end
    end
    
    it "optimizes form inputs for mobile" do
      visit ged_dashboard_path
      click_button "Nouveau Document"
      
      within '.modal' do
        # Les inputs doivent avoir les bons types pour mobile
        expect(page).to have_css('input[type="text"][autocomplete]')
        expect(page).to have_css('input[type="email"][autocomplete="email"]')
        expect(page).to have_css('input[type="tel"][autocomplete="tel"]')
        expect(page).to have_css('input[type="date"]') # Native date picker
        
        # Labels au-dessus des champs sur mobile
        expect(page).to have_css('.form-group.mobile-stacked')
      end
    end
    
    it "handles file upload on mobile" do
      visit ged_dashboard_path
      click_button "Nouveau Document"
      
      within '.modal' do
        # Options d'upload mobile
        expect(page).to have_button("Prendre une photo")
        expect(page).to have_button("Choisir depuis la galerie")
        expect(page).to have_button("Parcourir les fichiers")
        
        # Simuler la prise de photo
        find('input[type="file"][accept*="image/*"][capture="camera"]', visible: false)
      end
    end
  end
  
  describe "touch interactions", js: true do
    before { set_viewport_size(:mobile) }
    
    it "supports touch-friendly interactions" do
      visit ged_space_path(space)
      
      # Les éléments interactifs doivent être assez grands
      touch_targets = all('.touchable')
      touch_targets.each do |target|
        width = target.native.size.width
        height = target.native.size.height
        expect([width, height].min).to be >= 44 # Minimum Apple HIG
      end
      
      # Long press pour menu contextuel
      document_element = find('.document-card')
      
      page.execute_script(<<-JS, document_element.native)
        var event = new TouchEvent('touchstart', {
          touches: [{ clientX: 100, clientY: 100 }]
        });
        arguments[0].dispatchEvent(event);
        
        setTimeout(() => {
          var event = new TouchEvent('touchend', {
            changedTouches: [{ clientX: 100, clientY: 100 }]
          });
          arguments[0].dispatchEvent(event);
        }, 1000);
      JS
      
      # Menu contextuel doit apparaître
      expect(page).to have_css('.context-menu-mobile')
    end
    
    it "provides swipeable image gallery" do
      # Créer un document avec des images
      3.times do |i|
        document.images.attach(
          io: File.open(Rails.root.join("spec/fixtures/image#{i}.jpg")),
          filename: "image#{i}.jpg"
        )
      end
      
      visit ged_document_path(document)
      
      # Ouvrir la galerie
      find('.document-image', match: :first).click
      
      expect(page).to have_css('.mobile-gallery')
      
      within '.mobile-gallery' do
        # Indicateurs de pagination
        expect(page).to have_css('.gallery-dots')
        expect(page).to have_css('.dot', count: 3)
        expect(page).to have_css('.dot.active')
        
        # Swipe pour naviguer
        page.execute_script <<-JS
          var gallery = document.querySelector('.gallery-viewport');
          var touch = new Touch({
            identifier: Date.now(),
            target: gallery,
            clientX: 300,
            clientY: 400
          });
          
          var touchstart = new TouchEvent('touchstart', {
            touches: [touch],
            targetTouches: [touch],
            changedTouches: [touch]
          });
          gallery.dispatchEvent(touchstart);
          
          var touchmove = new TouchEvent('touchmove', {
            touches: [{ ...touch, clientX: 50 }],
            targetTouches: [{ ...touch, clientX: 50 }],
            changedTouches: [{ ...touch, clientX: 50 }]
          });
          gallery.dispatchEvent(touchmove);
          
          var touchend = new TouchEvent('touchend', {
            touches: [],
            targetTouches: [],
            changedTouches: [{ ...touch, clientX: 50 }]
          });
          gallery.dispatchEvent(touchend);
        JS
        
        # Doit passer à l'image suivante
        expect(page).to have_css('.dot.active:nth-child(2)')
      end
    end
  end
  
  describe "offline capabilities", js: true do
    before { set_viewport_size(:mobile) }
    
    it "shows offline indicator" do
      visit ged_dashboard_path
      
      # Simuler la perte de connexion
      page.execute_script("window.dispatchEvent(new Event('offline'));")
      
      expect(page).to have_css('.offline-banner')
      expect(page).to have_content("Vous êtes hors ligne")
      
      # Les actions non disponibles doivent être désactivées
      expect(page).to have_button("Nouveau Document", disabled: true)
      
      # Retour en ligne
      page.execute_script("window.dispatchEvent(new Event('online'));")
      
      expect(page).not_to have_css('.offline-banner')
      expect(page).to have_button("Nouveau Document", disabled: false)
    end
    
    it "queues actions for sync when offline" do
      visit ged_document_path(document)
      
      # Passer hors ligne
      page.execute_script("window.dispatchEvent(new Event('offline'));")
      
      # Essayer de modifier le document
      click_button "Modifier"
      fill_in "title", with: "Titre modifié hors ligne"
      click_button "Enregistrer"
      
      # Message de mise en file d'attente
      expect(page).to have_content("Modification enregistrée localement")
      expect(page).to have_css('.sync-queue-indicator')
      expect(page).to have_content("1 action en attente")
      
      # Retour en ligne
      page.execute_script("window.dispatchEvent(new Event('online'));")
      
      # Synchronisation automatique
      expect(page).to have_content("Synchronisation en cours...")
      expect(page).to have_content("Synchronisation terminée", wait: 5)
      expect(page).not_to have_css('.sync-queue-indicator')
    end
  end
  
  describe "performance on mobile", js: true do
    before do
      set_viewport_size(:mobile)
      # Créer beaucoup de documents pour tester les performances
      30.times { |i| create(:document, title: "Perf Test #{i}", space: space) }
    end
    
    it "implements infinite scroll on mobile" do
      visit ged_space_path(space)
      
      # Seuls les premiers documents doivent être chargés
      expect(page).to have_css('.document-card', count: 10)
      
      # Scroll vers le bas
      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      
      # Attendre le chargement
      expect(page).to have_css('.loading-spinner')
      expect(page).to have_css('.document-card', count: 20, wait: 3)
      
      # Continuer le scroll
      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      
      expect(page).to have_css('.document-card', count: 30, wait: 3)
      expect(page).to have_content("Tous les documents chargés")
    end
    
    it "lazy loads images" do
      # Attacher des images aux documents
      Document.limit(10).each do |doc|
        doc.preview.attach(
          io: File.open(Rails.root.join("spec/fixtures/preview.jpg")),
          filename: "preview.jpg"
        )
      end
      
      visit ged_space_path(space)
      
      # Les images hors viewport ne doivent pas être chargées
      images = all('img[data-lazy]')
      expect(images.count).to be > 0
      
      # Vérifier que seules les images visibles sont chargées
      page.execute_script <<-JS
        return Array.from(document.querySelectorAll('img[data-lazy]')).filter(img => {
          const rect = img.getBoundingClientRect();
          return rect.top < window.innerHeight && rect.bottom > 0;
        }).length;
      JS
      
      visible_count = page.evaluate_script("return window.lazyLoadedCount;")
      expect(visible_count).to be < images.count
    end
  end
  
  describe "responsive tables and data", js: true do
    it "transforms complex tables for mobile" do
      set_viewport_size(:mobile)
      
      # Page avec tableau de données complexe
      visit ged_reports_path
      
      # Sur mobile, le tableau doit être transformé
      expect(page).not_to have_css('table.complex-table')
      expect(page).to have_css('.mobile-data-cards')
      
      within first('.mobile-data-card') do
        # Données principales en évidence
        expect(page).to have_css('.primary-data')
        
        # Détails repliables
        expect(page).to have_button("Voir plus")
        click_button "Voir plus"
        
        expect(page).to have_css('.extended-details')
      end
    end
  end
end