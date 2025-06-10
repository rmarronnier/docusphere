require 'rails_helper'

RSpec.describe "Lookbook Screenshots", type: :system, js: true do
  before do
    driven_by(:selenium_chrome_headless)
    # Login si nécessaire
    # login_as(create(:user, :admin))
  end

  describe "Capturing component previews" do
    it "captures DataGrid component variations" do
      visit "/rails/lookbook"
      expect(page).to have_content("Docusphere Components")
      take_screenshot("lookbook_00_home")
      
      # DataGrid default
      visit "/rails/lookbook/preview/ui/data_grid_component/default"
      sleep 1
      take_screenshot("lookbook_01_data_grid_default")
      
      # DataGrid with actions
      visit "/rails/lookbook/preview/ui/data_grid_component/with_inline_actions"
      sleep 1
      take_screenshot("lookbook_02_data_grid_actions")
      
      # DataGrid formatting
      visit "/rails/lookbook/preview/ui/data_grid_component/with_formatting"
      sleep 1
      take_screenshot("lookbook_03_data_grid_formatting")
      
      # DataGrid empty state
      visit "/rails/lookbook/preview/ui/data_grid_component/empty_default"
      sleep 1
      take_screenshot("lookbook_04_data_grid_empty")
    end
    
    it "captures Button component variations" do
      # Button variants
      visit "/rails/lookbook/preview/ui/button_component/variants"
      sleep 1
      take_screenshot("lookbook_05_button_variants")
      
      # Button sizes
      visit "/rails/lookbook/preview/ui/button_component/sizes"
      sleep 1
      take_screenshot("lookbook_06_button_sizes")
    end
    
    it "captures Card component variations" do
      # Card default
      visit "/rails/lookbook/preview/ui/card_component/default"
      sleep 1
      take_screenshot("lookbook_07_card_default")
      
      # Card with footer
      visit "/rails/lookbook/preview/ui/card_component/with_footer"
      sleep 1
      take_screenshot("lookbook_08_card_footer")
    end
    
    it "captures Alert component variations" do
      # Alert types
      visit "/rails/lookbook/preview/ui/alert_component/types"
      sleep 1
      take_screenshot("lookbook_09_alert_types")
    end
    
    it "captures Modal component" do
      # Modal default (note: might not show if it's closed by default)
      visit "/rails/lookbook/preview/ui/modal_component/default"
      sleep 1
      take_screenshot("lookbook_10_modal_default")
    end
    
    it "captures EmptyState variations" do
      # Empty state variations
      visit "/rails/lookbook/preview/ui/empty_state_component/icon_variations"
      sleep 1
      take_screenshot("lookbook_11_empty_states")
    end
  end
  
  describe "Mobile responsiveness" do
    before do
      page.driver.browser.manage.window.resize_to(375, 812) # iPhone X size
    end
    
    it "captures mobile views" do
      # DataGrid mobile
      visit "/rails/lookbook/preview/ui/data_grid_component/default"
      sleep 1
      take_screenshot("lookbook_12_data_grid_mobile")
      
      # Buttons mobile
      visit "/rails/lookbook/preview/ui/button_component/variants"
      sleep 1
      take_screenshot("lookbook_13_button_mobile")
    end
  end
end