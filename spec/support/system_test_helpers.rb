# Helper methods for system tests
module SystemTestHelpers
  # Attendre qu'un élément soit visible
  def wait_for_element(selector, visible: true)
    has_css?(selector, visible: visible, wait: 5)
  end
  
  # Attendre qu'un job Sidekiq soit terminé
  def wait_for_sidekiq
    Timeout.timeout(10) do
      while Sidekiq::Queue.new.size > 0 || Sidekiq::Workers.new.size > 0
        sleep 0.1
      end
    end
  end
  
  # Helper pour remplir un formulaire dans une modale
  def fill_modal_form(modal_id, fields)
    within "##{modal_id}" do
      fields.each do |field, value|
        case field
        when /select|dropdown/
          select value, from: field
        when /file|upload/
          attach_file field, value
        when /checkbox/
          check field
        else
          fill_in field, with: value
        end
      end
    end
  end
  
  # Helper pour tester les messages flash
  def expect_flash_message(type, message)
    within ".flash.flash-#{type}" do
      expect(page).to have_content(message)
    end
  end
  
  # Helper pour simuler le drag & drop
  def drag_and_drop_file(source_selector, target_selector, file_path)
    source = find(source_selector)
    target = find(target_selector)
    
    # Simuler le drag & drop avec Selenium
    source.drag_to(target)
    
    # Ou utiliser JavaScript pour une simulation plus précise
    execute_script <<-JS
      var dataTransfer = new DataTransfer();
      var file = new File(['#{File.read(file_path)}'], '#{File.basename(file_path)}');
      dataTransfer.items.add(file);
      
      var dragEvent = new DragEvent('drop', {
        dataTransfer: dataTransfer,
        bubbles: true,
        cancelable: true
      });
      
      document.querySelector('#{target_selector}').dispatchEvent(dragEvent);
    JS
  end
  
  # Helper pour attendre une requête AJAX
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
  end
  
  # Helper pour tester l'autocomplete
  def fill_in_autocomplete(field, with:, select:)
    fill_in field, with: with
    
    # Attendre les suggestions
    expect(page).to have_css('.autocomplete-suggestions', visible: true)
    
    # Sélectionner l'option
    within '.autocomplete-suggestions' do
      click_on select
    end
  end
  
  # Helper pour prendre un screenshot avec un nom descriptif
  def take_screenshot_with_name(name)
    page.save_screenshot("tmp/screenshots/#{name}_#{Time.now.to_i}.png")
  end
  
  # Helper pour tester les téléchargements
  def download_file(link_text)
    # Configure Capybara pour les téléchargements
    download_path = Rails.root.join('tmp/downloads')
    FileUtils.mkdir_p(download_path)
    
    page.driver.browser.download_path = download_path.to_s
    
    click_link link_text
    
    # Attendre que le fichier soit téléchargé
    Timeout.timeout(10) do
      sleep 0.1 until Dir[download_path.join('*')].any?
    end
    
    # Retourner le chemin du fichier téléchargé
    Dir[download_path.join('*')].first
  end
  
  # Helper pour simuler un utilisateur mobile
  def use_mobile_viewport
    page.driver.browser.manage.window.resize_to(375, 667)
  end
  
  # Helper pour simuler un utilisateur desktop
  def use_desktop_viewport
    page.driver.browser.manage.window.resize_to(1920, 1080)
  end
end

# Inclure dans RSpec
RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
  config.include SystemTestHelpers, type: :feature
end