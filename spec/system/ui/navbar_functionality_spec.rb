require 'rails_helper'

RSpec.describe 'Navbar functionality', type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in user
  end

  describe 'User dropdown menu' do
    it 'opens and closes properly' do
      visit root_path
      
      # Find the user menu button by looking for the user initial or email
      expected_initial = user.first_name&.first&.upcase || user.email.first.upcase
      user_menu_button = find('button[data-action*="dropdown#toggle"]', text: expected_initial)
      
      # Find the dropdown menu associated with this button
      dropdown_container = user_menu_button.ancestor('[data-controller*="dropdown"]')
      dropdown_menu = dropdown_container.find('[data-dropdown-target="menu"]')
      
      # Initially dropdown should be hidden
      expect(dropdown_menu[:class]).to include('hidden')
      
      # Click to open dropdown
      user_menu_button.click
      sleep 0.1 # Wait for animation
      
      # Dropdown should be visible
      expect(dropdown_menu[:class]).not_to include('hidden')
      expect(page).to have_link('Mon profil')
      expect(page).to have_link('Notifications')
      expect(page).to have_link('Déconnexion')
      
      # Click outside to close
      find('body').click
      sleep 0.1 # Wait for animation
      
      # Dropdown should be hidden again
      expect(dropdown_menu[:class]).to include('hidden')
    end
  end

  describe 'Search functionality' do
    it 'search form submits correctly' do
      visit root_path
      
      # Find search input
      search_input = find('input[name="q"]')
      
      # Type search query
      search_input.fill_in with: 'test document'
      
      # Submit form
      search_input.send_keys(:return)
      
      # Should redirect to search page
      expect(page).to have_current_path('/search?q=test+document')
    end

    it 'search autocomplete controller is loaded' do
      visit root_path
      
      # Check that search autocomplete controller is present
      expect(page).to have_css('[data-controller*="search-autocomplete"]')
      expect(page).to have_css('[data-search-autocomplete-target="input"]')
      expect(page).to have_css('[data-search-autocomplete-target="suggestions"]')
    end
  end

  describe 'Notification bell' do
    it 'renders notification bell component' do
      visit root_path
      
      # Check notification bell is present
      expect(page).to have_css('[data-controller*="notification-bell"]')
      # Check for the bell icon specifically in the notification area
      notification_area = find('[data-controller*="notification-bell"]')
      expect(notification_area).to have_css('svg')
    end
  end

  describe 'JavaScript controllers loading' do
    it 'loads all required Stimulus controllers' do
      visit root_path
      
      # Check that JavaScript is working by verifying Stimulus controllers are connected
      expect(page).to have_css('[data-controller*="dropdown"]')
      expect(page).to have_css('[data-controller*="search-autocomplete"]')
      expect(page).to have_css('[data-controller*="notification-bell"]')
    end
  end
end