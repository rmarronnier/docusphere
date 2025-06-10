namespace :lookbook do
  desc "Capture screenshots of all Lookbook component previews"
  task capture: :environment do
    require 'net/http'
    require 'uri'
    require 'json'
    
    # Utiliser l'API Selenium directement depuis l'hôte
    class LookbookCapture
      SELENIUM_URL = "http://selenium:4444"
      BASE_URL = "http://web:3000"  # Accès au serveur web depuis Selenium
      SCREENSHOT_DIR = Rails.root.join('tmp', 'screenshots', 'lookbook_automated')
      
      def initialize
        FileUtils.mkdir_p(SCREENSHOT_DIR)
        @session_id = nil
      end
      
      def capture_all
        puts "🚀 Starting automated Lookbook screenshot capture..."
        
        # Créer une session Selenium
        create_session
        
        # Liste des composants à capturer - Sélection des scenarios les plus représentatifs
        components = [
          ["/rails/lookbook", "00_lookbook_home"],
          
          # UI Components
          ["/rails/lookbook/preview/ui/button/default", "01_button_default"],
          ["/rails/lookbook/preview/ui/button/variants", "02_button_variants"],
          ["/rails/lookbook/preview/ui/button/sizes", "03_button_sizes"],
          
          ["/rails/lookbook/preview/ui/data_grid/default", "04_data_grid_default"],
          ["/rails/lookbook/preview/ui/data_grid/with_inline_actions", "05_data_grid_actions"],
          ["/rails/lookbook/preview/ui/data_grid/with_formatting", "06_data_grid_formatting"],
          ["/rails/lookbook/preview/ui/data_grid/empty_default", "07_data_grid_empty"],
          
          ["/rails/lookbook/preview/ui/card/default", "08_card_default"],
          ["/rails/lookbook/preview/ui/card/with_footer", "09_card_footer"],
          
          ["/rails/lookbook/preview/ui/alert/types", "10_alert_types"],
          ["/rails/lookbook/preview/ui/alert/dismissible", "11_alert_dismissible"],
          
          ["/rails/lookbook/preview/ui/modal/default", "12_modal_default"],
          ["/rails/lookbook/preview/ui/modal/sizes", "13_modal_sizes"],
          
          ["/rails/lookbook/preview/ui/empty_state/default", "14_empty_state_default"],
          ["/rails/lookbook/preview/ui/empty_state/icon_variations", "15_empty_state_icons"],
          
          # New Components
          ["/rails/lookbook/preview/ui/status_badge/all_statuses", "16_status_badges"],
          ["/rails/lookbook/preview/ui/icon/common_icons", "17_icons"],
          ["/rails/lookbook/preview/ui/progress_bar/progress_values", "18_progress_bars"],
          ["/rails/lookbook/preview/ui/user_avatar/sizes", "19_user_avatars"],
          ["/rails/lookbook/preview/ui/stat_card/multiple_stats", "20_stat_cards"],
          ["/rails/lookbook/preview/ui/dropdown/variants", "21_dropdowns"],
          ["/rails/lookbook/preview/ui/notification/all_types", "22_notifications"],
          
          # Form Components
          ["/rails/lookbook/preview/forms/field/field_types", "23_form_fields"],
          ["/rails/lookbook/preview/forms/search_form/default", "24_search_form"],
          
          # Navigation Components
          ["/rails/lookbook/preview/navigation/breadcrumb/default", "25_breadcrumb"],
          
          # Document Components
          ["/rails/lookbook/preview/documents/document_card/different_types", "26_document_cards"]
        ]
        
        # Capturer chaque composant
        components.each do |path, name|
          capture_component(path, name)
        end
        
        # Capturer aussi en mobile
        puts "\n📱 Capturing mobile views..."
        set_window_size(375, 812)  # iPhone X size
        
        mobile_components = [
          ["/rails/lookbook/preview/ui/data_grid/default", "27_data_grid_mobile"],
          ["/rails/lookbook/preview/ui/button/variants", "28_button_mobile"],
          ["/rails/lookbook/preview/ui/card/default", "29_card_mobile"],
          ["/rails/lookbook/preview/documents/document_card/different_types", "30_document_cards_mobile"]
        ]
        
        mobile_components.each do |path, name|
          capture_component(path, name)
        end
        
        puts "\n✨ Screenshots saved to: #{SCREENSHOT_DIR}"
        puts "Run 'open #{SCREENSHOT_DIR}' to view them"
        
      ensure
        close_session if @session_id
      end
      
      private
      
      def create_session
        uri = URI("#{SELENIUM_URL}/wd/hub/session")
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = {
          capabilities: {
            firstMatch: [{}],
            alwaysMatch: {
              browserName: 'chrome',
              'goog:chromeOptions': {
                args: [
                  '--headless',
                  '--no-sandbox',
                  '--disable-dev-shm-usage',
                  '--window-size=1400,1024',
                  '--force-device-scale-factor=1'
                ]
              }
            }
          }
        }.to_json
        
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
        
        if response.code == '200'
          data = JSON.parse(response.body)
          @session_id = data['value']['sessionId']
          puts "✅ Created Selenium session: #{@session_id}"
        else
          raise "Failed to create session: #{response.code} - #{response.body}"
        end
      end
      
      def navigate_to(url)
        uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}/url")
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = { url: url }.to_json
        
        Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
      end
      
      def take_screenshot
        uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}/screenshot")
        request = Net::HTTP::Get.new(uri)
        
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
        
        if response.code == '200'
          data = JSON.parse(response.body)
          data['value']  # Base64 encoded screenshot
        else
          raise "Failed to take screenshot: #{response.code}"
        end
      end
      
      def set_window_size(width, height)
        uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}/window/rect")
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = { width: width, height: height }.to_json
        
        Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
      end
      
      def wait_for_page_load
        # Attendre que la page soit chargée
        sleep 3
        
        # Pour les previews Lookbook, attendre un peu plus pour l'iframe
        sleep 1
      end
      
      def capture_component(path, name)
        begin
          puts "  Capturing #{name}..."
          
          # Naviguer vers l'URL
          full_url = "#{BASE_URL}#{path}"
          navigate_to(full_url)
          
          # Attendre le chargement
          wait_for_page_load
          
          # Prendre le screenshot
          screenshot_base64 = take_screenshot
          
          # Sauvegarder le fichier
          screenshot_path = SCREENSHOT_DIR.join("#{name}.png")
          File.open(screenshot_path, 'wb') do |file|
            file.write(Base64.decode64(screenshot_base64))
          end
          
          puts "  ✅ Saved: #{name}.png"
          
        rescue => e
          puts "  ❌ Error capturing #{name}: #{e.message}"
        end
      end
      
      def close_session
        uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}")
        request = Net::HTTP::Delete.new(uri)
        
        Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
        
        puts "🔚 Closed Selenium session"
      rescue => e
        puts "Warning: Failed to close session: #{e.message}"
      end
    end
    
    # Exécuter la capture
    capture = LookbookCapture.new
    capture.capture_all
  end
end