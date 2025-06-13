require 'rails_helper'

RSpec.describe "Document Viewer Interactions", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  
  before do
    sign_in user
  end

  describe "Document viewer page" do
    before do
      visit ged_document_path(document)
    end

    it "loads the page successfully" do
      expect(page).to have_content(document.title)
      expect(page).to have_current_path(ged_document_path(document))
    end

    it "shows JavaScript console logs", :debug do
      # Check if application.js loaded
      logs = page.driver.browser.logs.get(:browser)
      puts "\n=== Browser Console Logs ==="
      logs.each { |log| puts "#{log.level}: #{log.message}" }
      puts "=========================\n"
      
      # Check for specific log messages
      expect(logs.map(&:message).join("\n")).to include("Application.js loaded")
    end

    context "document actions dropdown" do
      it "shows the actions menu button" do
        expect(page).to have_css('[data-controller="dropdown"]')
        expect(page).to have_css('[data-action="click->dropdown#toggle"]')
      end

      it "opens the dropdown menu when clicked", :debug do
        # Find and click the dropdown button
        dropdown_button = find('[data-action="click->dropdown#toggle"]')
        dropdown_button.click
        
        # Wait for menu to appear
        expect(page).to have_css('[data-dropdown-target="menu"]:not(.hidden)', wait: 5)
        
        # Check console logs
        logs = page.driver.browser.logs.get(:browser)
        puts "\n=== Dropdown Click Logs ==="
        logs.each { |log| puts "#{log.level}: #{log.message}" }
        puts "=========================\n"
      end
    end

    context "document sidebar tabs" do
      it "shows the sidebar with tabs" do
        expect(page).to have_css('[data-controller="document-sidebar"]')
        expect(page).to have_button("Information")
        expect(page).to have_button("Metadata")
        expect(page).to have_button("Activity")
      end

      it "switches tabs when clicked", :debug do
        # Click on Metadata tab
        click_button "Metadata"
        
        # Check if metadata content is shown
        expect(page).to have_css('[data-document-sidebar-target="metadataTab"]:not(.hidden)', wait: 5)
        
        # Check console logs
        logs = page.driver.browser.logs.get(:browser)
        puts "\n=== Tab Click Logs ==="
        logs.each { |log| puts "#{log.level}: #{log.message}" }
        puts "=========================\n"
      end
    end

    context "Stimulus controller loading" do
      it "loads Stimulus controllers", :debug do
        # Execute JavaScript to check if Stimulus is loaded
        stimulus_loaded = page.evaluate_script("typeof window.Stimulus !== 'undefined'")
        expect(stimulus_loaded).to be true
        
        # Check if specific controllers are registered
        dropdown_registered = page.evaluate_script("""
          if (window.Stimulus && window.Stimulus.application) {
            const controllers = Array.from(window.Stimulus.application.controllers);
            controllers.some(c => c.identifier === 'dropdown');
          } else {
            false;
          }
        """)
        
        puts "\n=== Stimulus Status ==="
        puts "Stimulus loaded: #{stimulus_loaded}"
        puts "Dropdown controller registered: #{dropdown_registered}"
        puts "=====================\n"
      end
    end
  end

  describe "Mobile menu" do
    before do
      visit root_path
      # Resize to mobile viewport
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    it "shows the mobile menu button" do
      expect(page).to have_css('[data-action="click->mobile-menu#toggle"]', visible: true)
    end

    it "toggles the mobile menu when clicked", :debug do
      # Click the mobile menu button
      find('[data-action="click->mobile-menu#toggle"]').click
      
      # Check if menu appears
      expect(page).to have_css('[data-mobile-menu-target="menu"]:not(.hidden)', wait: 5)
      
      # Check console logs
      logs = page.driver.browser.logs.get(:browser)
      puts "\n=== Mobile Menu Logs ==="
      logs.each { |log| puts "#{log.level}: #{log.message}" }
      puts "=========================\n"
    end
  end
end