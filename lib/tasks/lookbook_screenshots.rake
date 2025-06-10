namespace :lookbook do
  desc "Capture screenshots of Lookbook components"
  task screenshots: :environment do
    require 'capybara'
    require 'capybara/dsl'
    require 'selenium-webdriver'
    
    class LookbookScreenshotCapture
      include Capybara::DSL
      
      def initialize
        setup_capybara
      end
      
      def setup_capybara
        # Configuration pour utiliser Selenium avec le service existant
        Capybara.register_driver :selenium_remote do |app|
          options = Selenium::WebDriver::Chrome::Options.new
          options.add_argument('--headless')
          options.add_argument('--no-sandbox')
          options.add_argument('--disable-dev-shm-usage')
          options.add_argument('--disable-gpu')
          options.add_argument('--window-size=1400,1024')
          
          # Ajouter un user-data-dir unique pour éviter les conflits
          options.add_argument("--user-data-dir=/tmp/chrome-#{Process.pid}")
          
          Capybara::Selenium::Driver.new(
            app,
            browser: :remote,
            url: "http://selenium:4444/wd/hub",
            options: options
          )
        end
        
        Capybara.current_driver = :selenium_remote
        Capybara.app_host = "http://web:3000"
        Capybara.default_max_wait_time = 10
      end
      
      def capture_all
        screenshots_dir = Rails.root.join('tmp', 'screenshots', 'lookbook')
        FileUtils.mkdir_p(screenshots_dir)
        
        puts "📸 Starting Lookbook screenshot capture..."
        
        components = [
          ["/rails/lookbook", "00_lookbook_home"],
          ["/rails/lookbook/preview/ui/data_grid_component_preview/default", "01_data_grid_default"],
          ["/rails/lookbook/preview/ui/data_grid_component_preview/with_inline_actions", "02_data_grid_actions"],
          ["/rails/lookbook/preview/ui/data_grid_component_preview/with_formatting", "03_data_grid_formatting"],
          ["/rails/lookbook/preview/ui/data_grid_component_preview/empty_default", "04_data_grid_empty"],
          ["/rails/lookbook/preview/ui/button_component_preview/variants", "05_button_variants"],
          ["/rails/lookbook/preview/ui/button_component_preview/sizes", "06_button_sizes"],
          ["/rails/lookbook/preview/ui/card_component_preview/default", "07_card_default"],
          ["/rails/lookbook/preview/ui/card_component_preview/with_footer", "08_card_footer"],
          ["/rails/lookbook/preview/ui/alert_component_preview/types", "09_alert_types"],
          ["/rails/lookbook/preview/ui/modal_component_preview/default", "10_modal_default"],
          ["/rails/lookbook/preview/ui/empty_state_component_preview/icon_variations", "11_empty_states"]
        ]
        
        components.each do |path, name|
          begin
            puts "  Capturing #{name}..."
            visit path
            sleep 2 # Attendre le chargement complet
            
            filename = screenshots_dir.join("#{name}.png")
            save_screenshot(filename.to_s)
            puts "  ✅ Saved: #{name}.png"
          rescue => e
            puts "  ❌ Error capturing #{name}: #{e.message}"
          end
        end
        
        puts "\n✨ Screenshots saved to: #{screenshots_dir}"
        puts "Run 'ls -la #{screenshots_dir}' to see all screenshots"
      rescue => e
        puts "❌ Fatal error: #{e.message}"
        puts e.backtrace.first(5).join("\n")
      ensure
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end
    end
    
    capture = LookbookScreenshotCapture.new
    capture.capture_all
  end
end