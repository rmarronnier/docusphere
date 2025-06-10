# Capybara configuration for system tests
require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

# Detect if we're running in Docker
def running_in_docker?
  ENV['DOCKER_CONTAINER'].present?
end

# Configure Capybara server
Capybara.server = :puma, { Silent: true }
Capybara.server_host = running_in_docker? ? '0.0.0.0' : 'localhost'
Capybara.server_port = 3001

# Basic Capybara configuration
Capybara.configure do |config|
  config.default_max_wait_time = 10  # Increased timeout for Docker environment
  config.default_normalize_ws = true
  config.save_path = Rails.root.join('tmp/screenshots')
  config.automatic_label_click = true
  config.disable_animation = true
  config.match = :prefer_exact
end

# Ensure screenshot directory exists
FileUtils.mkdir_p(Capybara.save_path)

if running_in_docker?
  # Remote Chrome driver for Docker
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-features=VizDisplayCompositor')
    options.add_argument('--window-size=1920,1080')
    
    # Additional stability options
    options.add_preference('download.default_directory', '/tmp')
    options.add_preference('download.prompt_for_download', false)
    options.add_preference('plugins.plugins_disabled', ['Chrome PDF Viewer'])
    
    # Important: Tell Capybara where to find the app from Selenium's perspective
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://selenium:4444/wd/hub",
      options: options
    )
  end
  
  # Set the app_host to the web container name in Docker network
  # This allows Selenium to connect to the Rails app
  Capybara.app_host = "http://web:3001"
  
  # Always include port since we're using a non-standard port
  Capybara.always_include_port = true
else
  # Local Chrome driver
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1920,1080')
    
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end
end

# Set default drivers
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :chrome

# RSpec configuration
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  
  config.before(:each, type: :system, js: true) do
    driven_by :chrome
  end
  
  # Screenshot on failure
  config.after(:each, type: :system) do |example|
    if example.exception && page.driver.respond_to?(:save_screenshot)
      begin
        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        screenshot_path = page.save_screenshot("failure_#{timestamp}.png")
        puts "\n📸 Screenshot: #{screenshot_path}"
      rescue Capybara::NotSupportedByDriverError
        # Silently skip screenshot for drivers that don't support it (like rack_test)
      end
    end
  end
end