require 'rails_helper'

RSpec.describe Ui::DataGridComponent::EmptyStateComponent, type: :component do
  describe "basic rendering" do
    it "renders default empty state" do
      render_inline(described_class.new)
      
      expect(page).to have_css("div.text-center.py-12")
      expect(page).to have_text("Aucune donnée disponible")
      expect(page).to have_css("svg", count: 1)
    end

    it "renders with custom message" do
      render_inline(described_class.new(message: "No results found"))
      
      expect(page).to have_text("No results found")
      expect(page).not_to have_text("Aucune donnée disponible")
    end

    it "renders without icon when show_icon is false" do
      render_inline(described_class.new(show_icon: false))
      
      expect(page).to have_text("Aucune donnée disponible")
      expect(page).not_to have_css("svg")
    end
  end

  describe "icon variants" do
    it "renders document icon by default" do
      render_inline(described_class.new)
      
      expect(page).to have_css("svg")
      # Check for document icon path pattern
      expect(page).to have_css("path[d*='M9 12h6m-6 4h6m2 5H7']")
    end

    it "renders folder icon" do
      render_inline(described_class.new(icon: "folder"))
      
      expect(page).to have_css("svg")
      # Check for folder icon path pattern
      expect(page).to have_css("path[d*='M3 7v10a2 2 0 002 2h14']")
    end

    it "renders search icon" do
      render_inline(described_class.new(icon: "search"))
      
      expect(page).to have_css("svg")
      # Check for search icon path pattern
      expect(page).to have_css("path[d*='M21 21l-6-6m2-5a7']")
    end

    it "renders inbox icon" do
      render_inline(described_class.new(icon: "inbox"))
      
      expect(page).to have_css("svg")
      # Check for inbox icon path pattern
      expect(page).to have_css("path[d*='M20 13V6a2 2 0 00-2-2H6']")
    end

    it "renders users icon" do
      render_inline(described_class.new(icon: "users"))
      
      expect(page).to have_css("svg")
      # Check for users icon path pattern
      expect(page).to have_css("path[d*='M12 4.354a4 4 0 110']")
    end

    it "renders default icon for unknown icon name" do
      render_inline(described_class.new(icon: "unknown"))
      
      expect(page).to have_css("svg")
      # Should render the default icon (inbox)
      expect(page).to have_css("path[d*='M20 13V6a2 2 0 00-2-2H6']")
    end
  end

  describe "custom content" do
    it "renders custom content when provided" do
      custom_html = %(<div class="custom-empty-state">
        <h3 class="text-lg font-medium">No items yet</h3>
        <p class="text-sm text-gray-500">Start by creating your first item</p>
        <button class="mt-4 btn btn-primary">Create Item</button>
      </div>).html_safe
      
      render_inline(described_class.new(custom_content: custom_html))
      
      expect(page).to have_css("div.custom-empty-state")
      expect(page).to have_css("h3", text: "No items yet")
      expect(page).to have_css("p", text: "Start by creating your first item")
      expect(page).to have_button("Create Item")
      
      # Should not render default content
      expect(page).not_to have_text("Aucune donnée disponible")
      expect(page).not_to have_css("div.text-center.py-12")
    end

    it "ignores other parameters when custom content is provided" do
      custom_html = "<div>Custom content</div>".html_safe
      
      render_inline(described_class.new(
        message: "This should be ignored",
        icon: "folder",
        show_icon: true,
        custom_content: custom_html
      ))
      
      expect(page).to have_text("Custom content")
      expect(page).not_to have_text("This should be ignored")
      expect(page).not_to have_css("svg")
    end
  end

  describe "styling" do
    it "applies correct CSS classes to default empty state" do
      render_inline(described_class.new)
      
      expect(page).to have_css("div.text-center.py-12")
      expect(page).to have_css("div.mx-auto.h-12.w-12.text-gray-400")
      expect(page).to have_css("p.mt-2.text-sm.text-gray-500")
    end

    it "maintains consistent icon size" do
      render_inline(described_class.new)
      
      expect(page).to have_css("svg.h-12.w-12")
    end
  end

  describe "real-world usage scenarios" do
    it "renders search empty state" do
      render_inline(described_class.new(
        message: "Aucun résultat trouvé pour votre recherche",
        icon: "search"
      ))
      
      expect(page).to have_text("Aucun résultat trouvé pour votre recherche")
      expect(page).to have_css("svg") # search icon
    end

    it "renders filtered data empty state" do
      render_inline(described_class.new(
        message: "Aucun élément ne correspond aux filtres appliqués",
        icon: "document"
      ))
      
      expect(page).to have_text("Aucun élément ne correspond aux filtres appliqués")
    end

    it "renders folder empty state" do
      render_inline(described_class.new(
        message: "Ce dossier est vide",
        icon: "folder"
      ))
      
      expect(page).to have_text("Ce dossier est vide")
    end
  end
end