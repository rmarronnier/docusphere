require 'rails_helper'

RSpec.describe "Lookbook Visual Tests", type: :system, js: true do
  before do
    # Créer un dossier spécifique pour les screenshots Lookbook
    @screenshots_dir = Rails.root.join('tmp', 'screenshots', 'lookbook_components')
    FileUtils.mkdir_p(@screenshots_dir)
  end

  def capture_lookbook_screenshot(path, filename)
    visit path
    sleep 2 # Attendre le chargement complet
    
    # Si on est dans un preview, il peut y avoir un iframe
    if path.include?("/preview/")
      begin
        # Essayer de basculer dans l'iframe si présent
        within_frame(find('iframe', wait: 2)) do
          sleep 1 # Attendre le contenu de l'iframe
          page.save_screenshot(@screenshots_dir.join(filename))
        end
      rescue Capybara::ElementNotFound
        # Pas d'iframe, capturer normalement
        page.save_screenshot(@screenshots_dir.join(filename))
      end
    else
      page.save_screenshot(@screenshots_dir.join(filename))
    end
    
    puts "✅ Captured: #{filename}"
  end

  describe "Component Screenshots" do
    it "captures Lookbook home page" do
      capture_lookbook_screenshot("/rails/lookbook", "00_lookbook_home.png")
      expect(page).to have_current_path(/lookbook/, wait: 5)
    end

    it "captures DataGrid component variations" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/default",
        "01_data_grid_default.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/with_inline_actions",
        "02_data_grid_inline_actions.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/with_dropdown_actions",
        "03_data_grid_dropdown_actions.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/with_formatting",
        "04_data_grid_formatting.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/empty_default",
        "05_data_grid_empty.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/empty_custom",
        "06_data_grid_empty_custom.png"
      )
    end

    it "captures Button component variations" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/button_component_preview/variants",
        "07_button_variants.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/button_component_preview/sizes",
        "08_button_sizes.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/button_component_preview/states",
        "09_button_states.png"
      )
    end

    it "captures Card component variations" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/card_component_preview/default",
        "10_card_default.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/card_component_preview/with_footer",
        "11_card_with_footer.png"
      )
    end

    it "captures Alert component variations" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/alert_component_preview/types",
        "12_alert_types.png"
      )
    end

    it "captures Modal component" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/modal_component_preview/default",
        "13_modal_default.png"
      )
    end

    it "captures EmptyState component variations" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/empty_state_component_preview/default",
        "14_empty_state_default.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/empty_state_component_preview/icon_variations",
        "15_empty_state_icons.png"
      )
    end
  end

  describe "Mobile Responsive Screenshots" do
    before do
      page.driver.browser.manage.window.resize_to(375, 812) # iPhone X size
    end

    it "captures mobile views" do
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/data_grid_component_preview/default",
        "16_data_grid_mobile.png"
      )
      
      capture_lookbook_screenshot(
        "/rails/lookbook/preview/ui/button_component_preview/variants",
        "17_button_mobile.png"
      )
    end
  end

  after(:all) do
    puts "\n✨ Screenshots saved to: #{@screenshots_dir}"
    puts "Run 'open #{@screenshots_dir}' to view them"
  end
end