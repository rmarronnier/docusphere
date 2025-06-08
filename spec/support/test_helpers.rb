# Comprehensive test helpers for RSpec

module TestHelpers
  # Authentication helpers
  module AuthenticationHelpers
    def sign_in_as(user)
      if respond_to?(:visit)
        # For feature/system specs
        visit new_user_session_path
        fill_in "Email", with: user.email
        fill_in "Mot de passe", with: user.password || "password123"
        click_button "Se connecter"
      else
        # For request specs
        post user_session_path, params: {
          user: { email: user.email, password: user.password || "password123" }
        }
      end
    end
    
    def sign_out
      if respond_to?(:visit)
        click_link "Déconnexion"
      else
        delete destroy_user_session_path
      end
    end
    
    def authenticated_headers(user)
      {
        "Authorization" => "Bearer #{user.authentication_token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    end
  end
  
  # File upload helpers
  module FileUploadHelpers
    def attach_test_file(field_name, filename = "test_document.pdf", type = "application/pdf")
      attach_file field_name, test_file_path(filename), make_visible: true
    end
    
    def test_file_path(filename)
      Rails.root.join("spec/fixtures/#{filename}")
    end
    
    def create_test_file(content = "Test content", filename = "test.txt")
      file = Tempfile.new([filename.split('.').first, ".#{filename.split('.').last}"])
      file.write(content)
      file.rewind
      file
    end
    
    def mock_file_upload(filename = "test.pdf", content_type = "application/pdf")
      Rack::Test::UploadedFile.new(
        test_file_path(filename),
        content_type
      )
    end
    
    # For drag and drop testing
    def drag_file_to(file_path, drop_zone_selector)
      drop_zone = find(drop_zone_selector)
      
      # Create a fake input
      page.execute_script <<-JS
        var fakeInput = document.createElement('input');
        fakeInput.type = 'file';
        fakeInput.id = 'fake-file-input';
        fakeInput.style.display = 'none';
        document.body.appendChild(fakeInput);
      JS
      
      # Attach file to fake input
      attach_file('fake-file-input', file_path, make_visible: false)
      
      # Simulate drag and drop
      page.execute_script <<-JS
        var dropZone = document.querySelector('#{drop_zone_selector}');
        var fakeInput = document.getElementById('fake-file-input');
        var file = fakeInput.files[0];
        
        var dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        
        var dropEvent = new DragEvent('drop', {
          dataTransfer: dataTransfer,
          bubbles: true,
          cancelable: true
        });
        
        dropZone.dispatchEvent(dropEvent);
        fakeInput.remove();
      JS
    end
  end
  
  # AJAX and async helpers
  module AsyncHelpers
    def wait_for_ajax
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop until finished_all_ajax_requests?
      end
    end
    
    def finished_all_ajax_requests?
      page.evaluate_script('jQuery.active').zero?
    rescue
      # If jQuery is not available, assume no AJAX
      true
    end
    
    def wait_for_turbo
      page.has_no_css?('.turbo-progress-bar', visible: true)
    end
    
    def wait_for_element(selector, visible: true, text: nil)
      options = { visible: visible }
      options[:text] = text if text
      page.has_css?(selector, **options)
    end
    
    def wait_until(timeout: 5, &block)
      Timeout.timeout(timeout) do
        loop until yield
        sleep 0.1
      end
    end
  end
  
  # Form helpers
  module FormHelpers
    def fill_in_form(fields)
      fields.each do |field, value|
        case field_type(field)
        when :select
          select value, from: field
        when :checkbox
          value ? check(field) : uncheck(field)
        when :radio
          choose field, option: value
        when :file
          attach_file field, value
        when :rich_text
          fill_in_rich_text field, with: value
        else
          fill_in field, with: value
        end
      end
    end
    
    def field_type(field_name)
      field = find_field(field_name)
      return :select if field.tag_name == 'select'
      return :checkbox if field['type'] == 'checkbox'
      return :radio if field['type'] == 'radio'
      return :file if field['type'] == 'file'
      return :rich_text if field['class']&.include?('trix-editor')
      :text
    rescue
      :text
    end
    
    def fill_in_rich_text(locator, with:)
      find(:rich_text_area, locator).set(with)
    end
    
    def submit_form(button_text = "Submit")
      click_button button_text
    end
    
    def form_has_errors?(*fields)
      fields.all? { |field| page.has_css?(".field_with_errors", text: field) }
    end
  end
  
  # Modal and dialog helpers
  module ModalHelpers
    def within_modal(modal_id = nil, &block)
      modal_selector = modal_id ? "##{modal_id}" : ".modal:not(.hidden)"
      within(modal_selector, &block)
    end
    
    def open_modal(trigger_text)
      click_button trigger_text
      wait_for_element('.modal:not(.hidden)')
    end
    
    def close_modal
      within('.modal:not(.hidden)') do
        click_button '×' if has_button?('×')
        click_button 'Fermer' if has_button?('Fermer')
        click_button 'Cancel' if has_button?('Cancel')
      end
    end
    
    def accept_confirm_dialog
      page.accept_confirm do
        yield
      end
    end
    
    def dismiss_confirm_dialog
      page.dismiss_confirm do
        yield
      end
    end
  end
  
  # Table helpers
  module TableHelpers
    def within_table_row(text, &block)
      within(:xpath, "//tr[contains(., '#{text}')]", &block)
    end
    
    def table_row_containing(text)
      find(:xpath, "//tr[contains(., '#{text}')]")
    end
    
    def click_table_action(row_text, action)
      within_table_row(row_text) do
        click_link action
      end
    end
    
    def table_has_content?(*texts)
      texts.all? { |text| page.has_css?('td', text: text) }
    end
    
    def sort_table_by(column_header)
      find('th', text: column_header).click
    end
  end
  
  # Navigation helpers
  module NavigationHelpers
    def visit_section(section)
      within('.navbar') do
        click_link section
      end
    end
    
    def breadcrumb_path
      all('.breadcrumb-item').map(&:text).join(' > ')
    end
    
    def go_back
      click_link 'Retour' if has_link?('Retour')
      page.go_back
    end
    
    def current_section
      find('.nav-link.active').text
    rescue
      nil
    end
  end
  
  # Search helpers
  module SearchHelpers
    def search_for(query, submit: true)
      fill_in "search", with: query
      click_button "Rechercher" if submit
    end
    
    def quick_search(query)
      within('.navbar-search') do
        fill_in "search", with: query
        wait_for_element('.search-suggestions')
      end
    end
    
    def select_search_suggestion(text)
      within('.search-suggestions') do
        click_link text
      end
    end
    
    def apply_search_filter(filter_name, value)
      within('.search-filters') do
        case filter_name
        when /tag/i
          check value
        when /date/i
          fill_in filter_name, with: value
        else
          select value, from: filter_name
        end
      end
    end
  end
  
  # Notification helpers
  module NotificationHelpers
    def expect_success_message(text = nil)
      if text
        expect(page).to have_css('.alert-success', text: text)
      else
        expect(page).to have_css('.alert-success')
      end
    end
    
    def expect_error_message(text = nil)
      if text
        expect(page).to have_css('.alert-danger', text: text)
      else
        expect(page).to have_css('.alert-danger')
      end
    end
    
    def dismiss_notification
      within('.alert') do
        click_button '×' if has_button?('×')
      end
    end
    
    def wait_for_notification_to_disappear
      page.has_no_css?('.alert', wait: 5)
    end
  end
  
  # Pagination helpers
  module PaginationHelpers
    def go_to_page(page_number)
      within('.pagination') do
        click_link page_number.to_s
      end
    end
    
    def go_to_next_page
      within('.pagination') do
        click_link 'Suivant' if has_link?('Suivant')
        click_link '›' if has_link?('›')
      end
    end
    
    def go_to_previous_page
      within('.pagination') do
        click_link 'Précédent' if has_link?('Précédent')
        click_link '‹' if has_link?('‹')
      end
    end
    
    def on_page?(page_number)
      within('.pagination') do
        has_css?('.active', text: page_number.to_s)
      end
    end
  end
  
  # Mobile helpers
  module MobileHelpers
    def use_mobile_view
      page.driver.browser.manage.window.resize_to(375, 812)
    end
    
    def use_tablet_view
      page.driver.browser.manage.window.resize_to(768, 1024)
    end
    
    def use_desktop_view
      page.driver.browser.manage.window.resize_to(1920, 1080)
    end
    
    def open_mobile_menu
      find('.mobile-menu-toggle').click
      wait_for_element('.mobile-menu.active')
    end
    
    def close_mobile_menu
      find('.mobile-menu-overlay').click if has_css?('.mobile-menu-overlay')
    end
    
    def swipe_left
      page.driver.browser.action
        .move_to_location(300, 400)
        .pointer_down
        .move_to_location(50, 400)
        .pointer_up
        .perform
    end
    
    def swipe_right
      page.driver.browser.action
        .move_to_location(50, 400)
        .pointer_down
        .move_to_location(300, 400)
        .pointer_up
        .perform
    end
  end
  
  # Performance helpers
  module PerformanceHelpers
    def measure_page_load_time
      start_time = Time.now
      yield
      wait_for_page_load
      Time.now - start_time
    end
    
    def wait_for_page_load
      page.has_css?('body')
      wait_for_ajax if respond_to?(:wait_for_ajax)
      wait_for_turbo if respond_to?(:wait_for_turbo)
    end
    
    def count_database_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name]&.include?('SCHEMA') }
      
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)
      count
    end
    
    def expect_no_n_plus_one_queries
      populate = proc { yield }
      expect { populate.call }.to perform_constant_number_of_queries
    end
  end
  
  # Debugging helpers
  module DebuggingHelpers
    def save_screenshot_with_name(name)
      page.save_screenshot("tmp/screenshots/#{name}_#{Time.now.to_i}.png")
    end
    
    def pause_test
      $stderr.puts "\n🔴 Test paused. Press enter to continue..."
      $stdin.gets
    end
    
    def debug_page
      save_screenshot_with_name("debug")
      save_page("tmp/pages/debug_#{Time.now.to_i}.html")
      
      puts "\n" + "=" * 80
      puts "Current URL: #{current_url}"
      puts "Page Title: #{page.title}"
      puts "=" * 80 + "\n"
    end
    
    def print_js_logs
      logs = page.driver.browser.logs.get(:browser)
      if logs.any?
        puts "\n📋 JavaScript Console Logs:"
        logs.each { |log| puts "  [#{log.level}] #{log.message}" }
      end
    end
  end
end

# Include all helpers in RSpec
RSpec.configure do |config|
  config.include TestHelpers::AuthenticationHelpers
  config.include TestHelpers::FileUploadHelpers
  config.include TestHelpers::AsyncHelpers, type: :system
  config.include TestHelpers::AsyncHelpers, type: :feature
  config.include TestHelpers::FormHelpers, type: :system
  config.include TestHelpers::FormHelpers, type: :feature
  config.include TestHelpers::ModalHelpers, type: :system
  config.include TestHelpers::ModalHelpers, type: :feature
  config.include TestHelpers::TableHelpers, type: :system
  config.include TestHelpers::TableHelpers, type: :feature
  config.include TestHelpers::NavigationHelpers, type: :system
  config.include TestHelpers::NavigationHelpers, type: :feature
  config.include TestHelpers::SearchHelpers, type: :system
  config.include TestHelpers::SearchHelpers, type: :feature
  config.include TestHelpers::NotificationHelpers, type: :system
  config.include TestHelpers::NotificationHelpers, type: :feature
  config.include TestHelpers::PaginationHelpers, type: :system
  config.include TestHelpers::PaginationHelpers, type: :feature
  config.include TestHelpers::MobileHelpers, type: :system
  config.include TestHelpers::PerformanceHelpers
  config.include TestHelpers::DebuggingHelpers
end