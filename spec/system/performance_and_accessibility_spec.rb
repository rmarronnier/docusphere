require 'rails_helper'
require 'benchmark'

RSpec.describe "Performance and Accessibility", type: :system do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  
  before do
    login_as(user, scope: :user)
  end
  
  describe "page load performance", js: true do
    before do
      # Créer des données de test
      50.times do |i|
        create(:document, 
          title: "Document #{i}",
          space: space,
          created_at: i.days.ago
        )
      end
    end
    
    it "loads dashboard within acceptable time" do
      load_time = Benchmark.realtime do
        visit ged_dashboard_path
        expect(page).to have_content("Gestion Électronique de Documents")
        expect(page).to have_css('.document-card')
      end
      
      expect(load_time).to be < 3.0 # Moins de 3 secondes
      
      # Vérifier les métriques de performance
      metrics = page.evaluate_script <<-JS
        const perfData = window.performance.timing;
        const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
        const domReadyTime = perfData.domContentLoadedEventEnd - perfData.navigationStart;
        const firstPaintTime = performance.getEntriesByType('paint')[0]?.startTime || 0;
        
        return {
          pageLoadTime: pageLoadTime,
          domReadyTime: domReadyTime,
          firstPaintTime: firstPaintTime
        };
      JS
      
      expect(metrics['pageLoadTime']).to be < 3000 # millisecondes
      expect(metrics['domReadyTime']).to be < 2000
      expect(metrics['firstPaintTime']).to be < 1000
    end
    
    it "implements progressive loading" do
      visit ged_space_path(space)
      
      # Contenu critique chargé en premier
      expect(page).to have_css('.page-header', wait: 0.5)
      expect(page).to have_css('.primary-navigation', wait: 0.5)
      
      # Squelettes de chargement pour le contenu
      expect(page).to have_css('.skeleton-loader')
      
      # Contenu réel remplace les squelettes
      expect(page).to have_css('.document-card', wait: 2)
      expect(page).not_to have_css('.skeleton-loader')
      
      # Images chargées en lazy loading
      images_loaded = page.evaluate_script <<-JS
        Array.from(document.querySelectorAll('img')).filter(img => img.complete).length
      JS
      
      total_images = page.evaluate_script("document.querySelectorAll('img').length")
      
      # Toutes les images ne doivent pas être chargées immédiatement
      expect(images_loaded).to be < total_images
    end
    
    it "caches resources effectively" do
      # Première visite
      visit ged_dashboard_path
      
      first_load_metrics = page.evaluate_script <<-JS
        const entries = performance.getEntriesByType('resource');
        return entries.map(e => ({
          name: e.name,
          duration: e.duration,
          transferSize: e.transferSize
        }));
      JS
      
      # Deuxième visite (devrait utiliser le cache)
      visit ged_space_path(space)
      visit ged_dashboard_path
      
      cached_load_metrics = page.evaluate_script <<-JS
        const entries = performance.getEntriesByType('resource');
        return entries.filter(e => e.name.includes('/assets/')).map(e => ({
          name: e.name,
          duration: e.duration,
          transferSize: e.transferSize
        }));
      JS
      
      # Les ressources cachées doivent avoir un transferSize de 0
      cached_resources = cached_load_metrics.select { |m| m['transferSize'] == 0 }
      expect(cached_resources).not_to be_empty
    end
  end
  
  describe "search performance", js: true do
    before do
      100.times do |i|
        create(:document, 
          title: "Searchable Doc #{i}",
          content: "Content with keyword#{i % 10}",
          space: space
        )
      end
    end
    
    it "provides fast search results" do
      visit search_path
      
      search_time = Benchmark.realtime do
        fill_in "q", with: "keyword5"
        click_button "Rechercher"
        expect(page).to have_css('.search-results')
        expect(page).to have_content("résultats")
      end
      
      expect(search_time).to be < 2.0
      
      # Vérifier le temps affiché
      within '.search-stats' do
        expect(page).to have_content(/en \d+\.\d+ secondes/)
        time_text = find('.search-time').text
        displayed_time = time_text.match(/(\d+\.\d+)/)[1].to_f
        expect(displayed_time).to be < 1.0
      end
    end
    
    it "implements search debouncing" do
      visit root_path
      
      search_input = find('.navbar input[name="search"]')
      
      # Taper rapidement
      request_count = 0
      page.execute_script <<-JS
        let originalFetch = window.fetch;
        window.fetchCount = 0;
        window.fetch = function(...args) {
          if (args[0].includes('/search/suggestions')) {
            window.fetchCount++;
          }
          return originalFetch.apply(this, args);
        };
      JS
      
      search_input.fill_in with: "t"
      sleep 0.1
      search_input.fill_in with: "te"
      sleep 0.1
      search_input.fill_in with: "tes"
      sleep 0.1
      search_input.fill_in with: "test"
      
      # Attendre le debounce
      sleep 0.4
      
      # Une seule requête devrait être faite
      request_count = page.evaluate_script("window.fetchCount")
      expect(request_count).to eq(1)
    end
  end
  
  describe "accessibility compliance", js: true do
    it "passes WCAG 2.1 AA standards" do
      visit ged_dashboard_path
      
      # Vérifier la structure sémantique
      expect(page).to have_css('header[role="banner"]')
      expect(page).to have_css('nav[role="navigation"]')
      expect(page).to have_css('main[role="main"]')
      expect(page).to have_css('footer[role="contentinfo"]')
      
      # Vérifier les landmarks ARIA
      landmarks = page.evaluate_script <<-JS
        Array.from(document.querySelectorAll('[role]')).map(el => ({
          role: el.getAttribute('role'),
          label: el.getAttribute('aria-label') || el.getAttribute('aria-labelledby')
        }));
      JS
      
      expect(landmarks).to include(
        hash_including('role' => 'search'),
        hash_including('role' => 'navigation')
      )
    end
    
    it "provides proper heading hierarchy" do
      visit ged_dashboard_path
      
      headings = page.evaluate_script <<-JS
        Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6')).map(h => ({
          level: parseInt(h.tagName[1]),
          text: h.textContent.trim()
        }));
      JS
      
      # Doit avoir exactement un H1
      h1_count = headings.count { |h| h['level'] == 1 }
      expect(h1_count).to eq(1)
      
      # Vérifier la hiérarchie (pas de sauts de niveaux)
      headings.each_cons(2) do |prev, curr|
        level_diff = curr['level'] - prev['level']
        expect(level_diff).to be <= 1
      end
    end
    
    it "ensures sufficient color contrast" do
      visit ged_dashboard_path
      
      # Vérifier le contraste des éléments de texte
      contrast_issues = page.evaluate_script <<-JS
        function getLuminance(color) {
          const rgb = color.match(/\\d+/g).map(Number);
          const [r, g, b] = rgb.map(val => {
            val = val / 255;
            return val <= 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * r + 0.7152 * g + 0.0722 * b;
        }
        
        function getContrastRatio(color1, color2) {
          const lum1 = getLuminance(color1);
          const lum2 = getLuminance(color2);
          const lighter = Math.max(lum1, lum2);
          const darker = Math.min(lum1, lum2);
          return (lighter + 0.05) / (darker + 0.05);
        }
        
        const issues = [];
        document.querySelectorAll('*').forEach(el => {
          const style = window.getComputedStyle(el);
          const color = style.color;
          const bgColor = style.backgroundColor;
          
          if (color !== 'rgba(0, 0, 0, 0)' && bgColor !== 'rgba(0, 0, 0, 0)') {
            const ratio = getContrastRatio(color, bgColor);
            const fontSize = parseFloat(style.fontSize);
            const fontWeight = style.fontWeight;
            
            const minRatio = (fontSize >= 18 || (fontSize >= 14 && fontWeight >= 700)) ? 3 : 4.5;
            
            if (ratio < minRatio) {
              issues.push({
                element: el.tagName,
                ratio: ratio.toFixed(2),
                required: minRatio
              });
            }
          }
        });
        
        return issues;
      JS
      
      expect(contrast_issues).to be_empty
    end
    
    it "supports keyboard navigation" do
      visit ged_dashboard_path
      
      # Tab through interactive elements
      tab_sequence = []
      
      10.times do
        page.send_keys :tab
        
        active_element = page.evaluate_script <<-JS
          const el = document.activeElement;
          ({
            tag: el.tagName,
            type: el.type,
            role: el.getAttribute('role'),
            label: el.getAttribute('aria-label') || el.textContent.trim().substring(0, 20)
          })
        JS
        
        tab_sequence << active_element
        
        # Vérifier que l'élément a un indicateur de focus visible
        has_focus_indicator = page.evaluate_script <<-JS
          const el = document.activeElement;
          const style = window.getComputedStyle(el);
          const hasFocusStyle = 
            style.outline !== 'none' || 
            style.boxShadow !== 'none' ||
            style.border !== style.borderColor;
          hasFocusStyle
        JS
        
        expect(has_focus_indicator).to be true
      end
      
      # Vérifier que tous les éléments interactifs sont accessibles
      interactive_elements = tab_sequence.map { |el| el['tag'] }.uniq
      expect(interactive_elements).to include('A', 'BUTTON', 'INPUT')
    end
    
    it "provides skip links" do
      visit ged_dashboard_path
      
      # Le premier élément focusable doit être un skip link
      page.send_keys :tab
      
      skip_link = page.evaluate_script <<-JS
        document.activeElement.classList.contains('skip-link') ||
        document.activeElement.textContent.includes('Aller au contenu')
      JS
      
      expect(skip_link).to be true
      
      # Activer le skip link
      page.send_keys :return
      
      # Le focus doit être sur le contenu principal
      focused_element = page.evaluate_script("document.activeElement.id || document.activeElement.tagName")
      expect(['main', 'MAIN', 'content']).to include(focused_element)
    end
    
    it "announces dynamic content changes" do
      visit ged_dashboard_path
      
      # Vérifier la présence de live regions
      expect(page).to have_css('[aria-live="polite"]')
      expect(page).to have_css('[aria-live="assertive"]')
      
      # Simuler une action qui génère une notification
      click_button "Nouveau Document"
      
      # Vérifier que la notification est annoncée
      notification_announced = page.evaluate_script <<-JS
        const liveRegion = document.querySelector('[aria-live="assertive"]');
        liveRegion && liveRegion.textContent.length > 0
      JS
      
      expect(notification_announced).to be true
    end
    
    it "provides alternative text for images" do
      # Créer un document avec images
      document = create(:document, space: space)
      document.images.attach(
        io: File.open(Rails.root.join("spec/fixtures/test_image.jpg")),
        filename: "test_image.jpg"
      )
      
      visit ged_document_path(document)
      
      # Toutes les images doivent avoir un alt text
      images_without_alt = page.evaluate_script <<-JS
        Array.from(document.querySelectorAll('img')).filter(img => 
          !img.hasAttribute('alt') || img.getAttribute('alt').trim() === ''
        ).length
      JS
      
      expect(images_without_alt).to eq(0)
      
      # Les images décoratives doivent avoir alt=""
      decorative_images = page.evaluate_script <<-JS
        Array.from(document.querySelectorAll('img[role="presentation"], img.decorative')).every(img => 
          img.getAttribute('alt') === ''
        )
      JS
      
      expect(decorative_images).to be true
    end
    
    it "supports screen readers" do
      visit ged_dashboard_path
      
      # Vérifier les attributs ARIA
      aria_elements = page.evaluate_script <<-JS
        const elements = document.querySelectorAll('[aria-label], [aria-describedby], [aria-labelledby]');
        Array.from(elements).map(el => ({
          tag: el.tagName,
          label: el.getAttribute('aria-label'),
          describedby: el.getAttribute('aria-describedby'),
          labelledby: el.getAttribute('aria-labelledby')
        }));
      JS
      
      expect(aria_elements).not_to be_empty
      
      # Les formulaires doivent avoir des labels appropriés
      form_fields = page.all('input:not([type="hidden"]), select, textarea')
      form_fields.each do |field|
        has_label = field['aria-label'].present? || 
                   field['aria-labelledby'].present? ||
                   page.has_css?("label[for='#{field['id']}']")
        
        expect(has_label).to be true
      end
    end
  end
  
  describe "error handling and recovery", js: true do
    it "handles network errors gracefully" do
      visit ged_dashboard_path
      
      # Simuler une erreur réseau
      page.execute_script <<-JS
        window.fetch = () => Promise.reject(new Error('Network error'));
      JS
      
      click_button "Nouveau Document"
      fill_in "document_title", with: "Test"
      click_button "Enregistrer"
      
      # Message d'erreur utilisateur-friendly
      expect(page).to have_content("Une erreur est survenue")
      expect(page).to have_button("Réessayer")
      
      # Les données du formulaire doivent être préservées
      expect(find_field("document_title").value).to eq("Test")
    end
    
    it "provides timeout handling" do
      visit ged_dashboard_path
      
      # Simuler une requête lente
      page.execute_script <<-JS
        const originalFetch = window.fetch;
        window.fetch = (url, options) => {
          if (url.includes('/documents')) {
            return new Promise(resolve => setTimeout(resolve, 10000));
          }
          return originalFetch(url, options);
        };
      JS
      
      click_button "Charger plus"
      
      # Indicateur de chargement
      expect(page).to have_css('.loading-spinner')
      
      # Message de timeout après délai
      expect(page).to have_content("La requête prend plus de temps que prévu", wait: 6)
      expect(page).to have_button("Annuler")
    end
  end
  
  describe "memory management", js: true do
    it "prevents memory leaks with proper cleanup" do
      initial_memory = page.evaluate_script <<-JS
        if (performance.memory) {
          performance.memory.usedJSHeapSize / 1048576; // Convert to MB
        } else {
          0;
        }
      JS
      
      # Naviguer plusieurs fois pour simuler l'usage
      5.times do
        visit ged_dashboard_path
        visit ged_space_path(space)
        visit search_path
      end
      
      # Forcer le garbage collection si disponible
      page.execute_script("if (window.gc) window.gc();")
      
      final_memory = page.evaluate_script <<-JS
        if (performance.memory) {
          performance.memory.usedJSHeapSize / 1048576;
        } else {
          0;
        }
      JS
      
      # La mémoire ne doit pas augmenter de façon significative
      memory_increase = final_memory - initial_memory
      expect(memory_increase).to be < 50 # Moins de 50MB d'augmentation
    end
    
    it "removes event listeners on navigation" do
      visit ged_dashboard_path
      
      # Compter les event listeners avant
      initial_listeners = page.evaluate_script <<-JS
        if (window.getEventListeners) {
          Object.values(getEventListeners(document)).flat().length;
        } else {
          // Fallback: compter les éléments avec data-action (Stimulus)
          document.querySelectorAll('[data-action]').length;
        }
      JS
      
      # Naviguer ailleurs
      visit ged_space_path(space)
      
      # Les listeners de la page précédente doivent être nettoyés
      current_listeners = page.evaluate_script <<-JS
        document.querySelectorAll('[data-action]').length;
      JS
      
      # Le nombre ne doit pas continuer à augmenter
      expect(current_listeners).to be <= initial_listeners * 1.5
    end
  end
end