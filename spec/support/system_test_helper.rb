# Helper module for system tests
module SystemTestHelper
  extend ActiveSupport::Concern

  included do
    # Common setup for all system tests
    before do
      # Ensure we have a clean session
      Capybara.reset_sessions!
      
      # Set window size for consistent testing
      page.driver.browser.manage.window.resize_to(1920, 1080) if page.driver.browser.respond_to?(:manage)
    end

    # Helper methods available in all system tests
    
    # Login helper using Warden test helpers
    def login_as_user(user = nil)
      user ||= create(:user)
      login_as(user, scope: :user)
      user
    end

    # Wait for AJAX requests to complete
    def wait_for_ajax
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop until page.evaluate_script('jQuery.active').zero?
      end
    rescue Timeout::Error
      # Continue if jQuery is not available or timeout
    end

    # Take a screenshot with a custom name
    def capture_screenshot(name)
      page.save_screenshot("tmp/screenshots/#{name}_#{Time.now.to_i}.png")
    end

    # Helper to check if element is visible
    def element_visible?(selector)
      page.has_selector?(selector, visible: true)
    end

    # Helper for debugging - pause execution and show browser
    def debug_here
      if ENV['DEBUG']
        puts "\n🔍 Debugging paused. Browser available at http://localhost:7900"
        puts "Press ENTER to continue..."
        $stdin.gets
      end
    end
  end
end

# Configure RSpec to include the helper in system tests
RSpec.configure do |config|
  config.include SystemTestHelper, type: :system
  
  # Additional system test configuration
  config.before(:suite) do
    # Ensure test files are served properly
    Rails.application.config.action_dispatch.show_exceptions = false
  end
end