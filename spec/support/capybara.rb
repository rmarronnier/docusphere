# Capybara configuration for system tests
require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

# Configure Capybara
Capybara.configure do |config|
  config.server = :puma, { Silent: true }
  config.default_max_wait_time = 5
  config.default_normalize_ws = true
  config.ignore_hidden_elements = true
  config.visible_text_only = true
  config.match = :prefer_exact
  config.exact = false
  config.raise_server_errors = true
  config.save_path = Rails.root.join('tmp/screenshots')
  # Important: Tell Capybara where the app is running
  config.app_host = "http://#{ENV.fetch('CAPYBARA_APP_HOST', 'web')}:3000"
  config.always_include_port = true
  config.server_host = '0.0.0.0'
  config.server_port = 3000
end

# Ensure screenshot directory exists
FileUtils.mkdir_p(Capybara.save_path)

# Detect if we're running in Docker
def running_in_docker?
  File.exist?('/.dockerenv') || ENV['DOCKER_CONTAINER'].present?
end

# Configure Selenium to use remote Chrome when in Docker
if running_in_docker?
  # Use remote Selenium service
  Capybara.register_driver :chrome_headless do |app|
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument('--headless=new')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('--disable-web-security')
    
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://selenium:4444/wd/hub",
      options: chrome_options
    )
  end
else
  # Local development - use local Chrome
  Capybara.register_driver :chrome_headless do |app|
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument('--headless=new')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: chrome_options
    )
  end
end

# Register Chrome visible driver for debugging
if running_in_docker?
  Capybara.register_driver :chrome_debug do |app|
    chrome_debug_options = Selenium::WebDriver::Chrome::Options.new
    chrome_debug_options.add_argument('--no-sandbox')
    chrome_debug_options.add_argument('--disable-dev-shm-usage')
    chrome_debug_options.add_argument('--window-size=1920,1080')
    
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://selenium:4444/wd/hub",
      options: chrome_debug_options
    )
  end
else
  Capybara.register_driver :chrome_debug do |app|
    chrome_debug_options = Selenium::WebDriver::Chrome::Options.new
    chrome_debug_options.add_argument('--no-sandbox')
    chrome_debug_options.add_argument('--disable-dev-shm-usage')
    chrome_debug_options.add_argument('--window-size=1920,1080')
    
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: chrome_debug_options
    )
  end
end

# Use headless Chrome by default
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :chrome_headless

# For debugging, you can temporarily change to :chrome_debug
# Capybara.javascript_driver = :chrome_debug

RSpec.configure do |config|
  # Clean up screenshots after each test
  config.after(:each, type: :system) do |example|
    if example.metadata[:screenshot] && example.exception
      # Keep screenshot for failed tests
      screenshot_path = page.save_screenshot
      puts "\n📷 Screenshot saved: #{screenshot_path}"
    end
  end
  
  # Configure driver for system tests
  config.before(:each, type: :system) do |example|
    # By default, use Chrome headless for all system tests
    driven_by :chrome_headless
    
    # Individual tests can override with metadata:
    # it "test name", driver: :rack_test do ... end
    # it "test name", driver: :chrome_debug do ... end
    if example.metadata[:driver]
      driven_by example.metadata[:driver]
    end
  end
  
  # Helper method for debugging specific tests
  config.define_derived_metadata(debug: true) do |metadata|
    metadata[:driver] = :chrome_debug
  end
end