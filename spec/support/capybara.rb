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
end

# Ensure screenshot directory exists
FileUtils.mkdir_p(Capybara.save_path)

# Chromium headless options for Docker
chrome_options = Selenium::WebDriver::Chrome::Options.new
chrome_options.binary = '/usr/bin/chromium'
chrome_options.add_argument('--headless=new')
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--disable-dev-shm-usage')
chrome_options.add_argument('--disable-gpu')
chrome_options.add_argument('--window-size=1920,1080')
chrome_options.add_argument('--disable-web-security')
chrome_options.add_argument('--disable-features=VizDisplayCompositor')

# Register Chromium headless driver
Capybara.register_driver :chrome_headless do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: chrome_options
  )
end

# Chromium visible options for debugging
chrome_debug_options = Selenium::WebDriver::Chrome::Options.new
chrome_debug_options.binary = '/usr/bin/chromium'
chrome_debug_options.add_argument('--no-sandbox')
chrome_debug_options.add_argument('--disable-dev-shm-usage')
chrome_debug_options.add_argument('--window-size=1920,1080')

# Register Chromium visible driver for debugging
Capybara.register_driver :chrome_debug do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: chrome_debug_options
  )
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
  
  # Use Chrome headless for system tests
  config.before(:each, type: :system) do |example|
    if example.metadata[:js] || example.metadata[:type] == :system
      driven_by :chrome_headless
    else
      driven_by :rack_test
    end
  end
  
  # For debugging individual tests, you can use:
  # driven_by :chrome_debug, using: :chrome, screen_size: [1920, 1080]
end