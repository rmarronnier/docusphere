require 'rails_helper'

RSpec.describe Ui::DataGridComponent::CellComponent, type: :component do
  let(:column) { Ui::DataGridComponent::ColumnComponent.new(key: :name, label: "Name") }
  let(:item) { { id: 1, name: "John Doe", email: "john@example.com", amount: 1000 } }

  describe "basic rendering" do
    it "renders a table cell with value" do
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td", text: "John Doe")
      expect(page).to have_css("td.px-6.whitespace-nowrap.text-sm")
    end

    it "extracts value from hash item" do
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("John Doe")
    end

    it "extracts value from object item" do
      object_item = OpenStruct.new(name: "Jane Smith")
      render_inline(described_class.new(item: object_item, column: column))
      
      expect(page).to have_text("Jane Smith")
    end

    it "accepts explicit value" do
      render_inline(described_class.new(item: item, column: column, value: "Custom Value"))
      
      expect(page).to have_text("Custom Value")
    end
  end

  describe "alignment" do
    it "applies left alignment by default" do
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td.text-left")
    end

    it "applies center alignment" do
      column = Ui::DataGridComponent::ColumnComponent.new(key: :name, label: "Name", align: :center)
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td.text-center")
    end

    it "applies right alignment" do
      column = Ui::DataGridComponent::ColumnComponent.new(key: :name, label: "Name", align: :right)
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td.text-right")
    end
  end

  describe "formatting" do
    it "formats currency values" do
      column = Ui::DataGridComponent::ColumnComponent.new(key: :amount, label: "Amount", format: :currency)
      render_inline(described_class.new(item: item, column: column))
      
      # The app seems to be using French locale (EUR)
      expect(page).to have_text("1 000,00 €")
    end

    it "formats percentage values" do
      item = { rate: 25.5 }
      column = Ui::DataGridComponent::ColumnComponent.new(key: :rate, label: "Rate", format: :percentage)
      render_inline(described_class.new(item: item, column: column))
      
      # The app seems to be using French locale
      expect(page).to have_text("25,5%")
    end

    it "formats date values" do
      item = { created_at: Date.new(2024, 1, 15) }
      column = Ui::DataGridComponent::ColumnComponent.new(key: :created_at, label: "Created", format: :date)
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("2024-01-15")
    end

    it "formats datetime values" do
      item = { created_at: DateTime.new(2024, 1, 15, 14, 30) }
      column = Ui::DataGridComponent::ColumnComponent.new(key: :created_at, label: "Created", format: :datetime)
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("2024-01-15 14:30")
    end

    it "formats boolean true values" do
      item = { active: true }
      column = Ui::DataGridComponent::ColumnComponent.new(key: :active, label: "Active", format: :boolean)
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("✓")
    end

    it "formats boolean false values" do
      item = { active: false }
      column = Ui::DataGridComponent::ColumnComponent.new(key: :active, label: "Active", format: :boolean)
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("✗")
    end

    it "formats with custom proc" do
      column = Ui::DataGridComponent::ColumnComponent.new(
        key: :name, 
        label: "Name", 
        format: ->(value) { value.upcase }
      )
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("JOHN DOE")
    end

    it "returns raw value when no format specified" do
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_text("John Doe")
    end
  end

  describe "links" do
    it "renders value as link when link option provided" do
      column = Ui::DataGridComponent::ColumnComponent.new(
        key: :name,
        label: "Name",
        link: ->(item) { "/users/#{item[:id]}" }
      )
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_link("John Doe", href: "/users/1")
      expect(page).to have_css("a.text-primary-600.hover\\:text-primary-900.font-medium")
    end
  end

  describe "custom component" do
    it "renders custom component when provided" do
      # Create a named component class to avoid anonymous class issues
      stub_const("TestCustomComponent", Class.new(ApplicationComponent) do
        def initialize(item:, value:)
          @item = item
          @value = value
        end

        def call
          content_tag :span, @value.upcase, class: "custom-component"
        end
      end)

      column = Ui::DataGridComponent::ColumnComponent.new(
        key: :name,
        label: "Name",
        component: TestCustomComponent
      )
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("span.custom-component", text: "JOHN DOE")
    end
  end

  describe "custom CSS classes" do
    it "applies custom cell class" do
      column = Ui::DataGridComponent::ColumnComponent.new(
        key: :name,
        label: "Name",
        cell_class: "custom-cell-class"
      )
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td.custom-cell-class")
    end
  end

  describe "nil handling" do
    it "handles nil values gracefully" do
      item = { name: nil }
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td")
      expect(page.text).to eq("")
    end

    it "handles missing keys gracefully" do
      item = { email: "john@example.com" } # no name key
      render_inline(described_class.new(item: item, column: column))
      
      expect(page).to have_css("td")
      expect(page.text).to eq("")
    end
  end
end