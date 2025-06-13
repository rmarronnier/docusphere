require 'rails_helper'

RSpec.describe Navigation::BreadcrumbComponent, type: :component do
  let(:basic_items) do
    [
      { name: "Projects", path: "/projects" },
      { name: "Project Alpha", path: "/projects/alpha" },
      { name: "Documents", path: "/projects/alpha/documents" }
    ]
  end

  describe "basic rendering" do
    it "renders breadcrumb navigation" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("nav[aria-label='Breadcrumb']")
      expect(page).to have_text("Projects")
      expect(page).to have_text("Project Alpha")
      expect(page).to have_text("Documents")
    end

    it "includes home link by default" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_text("Accueil")
      expect(page).to have_link("Accueil", href: "/")
    end

    it "can hide home link" do
      render_inline(described_class.new(items: basic_items, show_home: false))
      
      expect(page).not_to have_text("Accueil")
    end

    it "uses custom root path for home" do
      render_inline(described_class.new(
        items: basic_items,
        root_path: "/dashboard"
      ))
      
      expect(page).to have_link("Accueil", href: "/dashboard")
    end
  end

  describe "item variations" do
    it "handles items with different key names" do
      items_with_variations = [
        { title: "First", url: "/first" },
        { label: "Second", href: "/second" },
        { name: "Third", path: "/third" }
      ]
      
      render_inline(described_class.new(items: items_with_variations))
      
      expect(page).to have_text("First")
      expect(page).to have_text("Second")
      expect(page).to have_text("Third")
    end

    it "handles items without paths (current page)" do
      items_with_current = [
        { name: "Parent", path: "/parent" },
        { name: "Current Page", path: nil }
      ]
      
      render_inline(described_class.new(items: items_with_current))
      
      expect(page).to have_link("Parent")
      expect(page).to have_text("Current Page")
      expect(page).not_to have_link("Current Page")
    end
  end

  describe "separators" do
    it "uses chevron separator by default" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("svg", minimum: 3) # Separators between items
    end

    it "uses slash separator" do
      render_inline(described_class.new(
        items: basic_items,
        separator: :slash
      ))
      
      expect(page).to have_text("/", minimum: 3)
    end

    it "uses dot separator" do
      render_inline(described_class.new(
        items: basic_items,
        separator: :dot
      ))
      
      expect(page).to have_text("•", minimum: 3)
    end

    it "uses arrow separator" do
      render_inline(described_class.new(
        items: basic_items,
        separator: :arrow
      ))
      
      expect(page).to have_css("svg") # Arrow icons
    end

    it "uses GED separator with custom SVG" do
      render_inline(described_class.new(
        items: basic_items,
        separator: :ged
      ))
      
      # Check for the specific SVG path used in GED
      expect(page).to have_css("svg path[d*='M5.555 17.776l8-16']")
    end
  end

  describe "truncation" do
    let(:many_items) do
      [
        { name: "Level 1", path: "/1" },
        { name: "Level 2", path: "/2" },
        { name: "Level 3", path: "/3" },
        { name: "Level 4", path: "/4" },
        { name: "Level 5", path: "/5" }
      ]
    end

    it "truncates long breadcrumbs by default" do
      render_inline(described_class.new(items: many_items))
      
      # The truncated indicator is shown as an icon, not text
      expect(page).to have_css("span.text-gray-400") # Truncation indicator span
      expect(page).to have_text("Level 1") # First item
      expect(page).to have_text("Level 4") # Second to last
      expect(page).to have_text("Level 5") # Last item
      expect(page).not_to have_text("Level 2")
      expect(page).not_to have_text("Level 3")
    end

    it "can disable truncation" do
      render_inline(described_class.new(
        items: many_items,
        truncate: false
      ))
      
      expect(page).not_to have_text("...")
      many_items.each do |item|
        expect(page).to have_text(item[:name])
      end
    end

    it "does not truncate short breadcrumbs" do
      short_items = basic_items[0..1]
      
      render_inline(described_class.new(items: short_items))
      
      expect(page).not_to have_text("...")
      short_items.each do |item|
        expect(page).to have_text(item[:name])
      end
    end
  end

  describe "styling" do
    it "styles the last item differently (current page)" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("span[aria-current='page']", text: "Documents")
      expect(page).to have_css(".text-gray-500", text: "Documents")
    end

    it "makes non-current items hoverable" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css(".hover\\:text-gray-700", text: "Projects")
      expect(page).to have_css(".hover\\:text-gray-700", text: "Project Alpha")
    end
  end

  describe "custom classes" do
    it "accepts custom wrapper classes" do
      render_inline(described_class.new(
        items: basic_items,
        class: "custom-breadcrumb"
      ))
      
      expect(page).to have_css(".flex.mb-6.custom-breadcrumb")
    end
  end

  describe "icons" do
    it "shows home icon for home link" do
      render_inline(described_class.new(items: basic_items))
      
      within("a[href='/']") do
        expect(page).to have_css("svg")
      end
    end

    it "can include icons in breadcrumb items" do
      items_with_icons = [
        { name: "Documents", path: "/docs", icon: "document" },
        { name: "Settings", path: "/settings", icon: "cog" }
      ]
      
      render_inline(described_class.new(items: items_with_icons))
      
      expect(page).to have_css("svg", minimum: 2)
    end
  end

  describe "accessibility" do
    it "uses semantic navigation element" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("nav[aria-label='Breadcrumb']")
    end

    it "marks current page appropriately" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("[aria-current='page']", text: "Documents")
    end

    it "uses ordered list for structure" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("ol")
      expect(page).to have_css("li", minimum: 4) # Including home
    end
  end

  describe "responsive behavior" do
    it "applies responsive text size" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css(".text-sm")
    end

    it "shows mobile back navigation by default" do
      render_inline(described_class.new(items: basic_items))
      
      expect(page).to have_css("nav.sm\\:hidden")
      expect(page).to have_text("Retour")
    end

    it "can hide mobile back navigation" do
      render_inline(described_class.new(
        items: basic_items,
        mobile_back: false
      ))
      
      expect(page).not_to have_css("nav.sm\\:hidden")
      expect(page).not_to have_text("Retour")
    end
  end

  describe "edge cases" do
    it "handles empty items array" do
      render_inline(described_class.new(items: []))
      
      expect(page).to have_css("nav[aria-label='Breadcrumb']")
      expect(page).to have_text("Accueil") # Only home is shown
    end

    it "handles single item" do
      render_inline(described_class.new(
        items: [{ name: "Dashboard", path: "/dashboard" }]
      ))
      
      expect(page).to have_text("Accueil")
      expect(page).to have_text("Dashboard")
    end

    it "handles items with missing names gracefully" do
      items_with_missing = [
        { path: "/test" },
        { name: "", path: "/empty" },
        { name: nil, path: "/nil" }
      ]
      
      render_inline(described_class.new(items: items_with_missing))
      
      expect(page).to have_text("Unknown", count: 3)
    end
  end
end