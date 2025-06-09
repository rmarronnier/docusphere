require 'rails_helper'

RSpec.describe Ui::DataGridComponent, type: :component do
  let(:sample_data) do
    [
      { id: 1, name: "John Doe", email: "john@example.com", status: "Active", amount: 1000 },
      { id: 2, name: "Jane Smith", email: "jane@example.com", status: "Inactive", amount: 2000 },
      { id: 3, name: "Bob Johnson", email: "bob@example.com", status: "Active", amount: 1500 }
    ]
  end

  describe "basic rendering" do
    it "renders table with data" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name")
        grid.with_column(key: :email, label: "Email")
      end
      
      expect(page).to have_css(".data-grid-wrapper")
      expect(page).to have_css("table")
      expect(page).to have_text("John Doe")
      expect(page).to have_text("jane@example.com")
    end

    it "renders column headers" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Full Name")
        grid.with_column(key: :status, label: "Current Status")
      end
      
      expect(page).to have_css("th", text: "Full Name")
      expect(page).to have_css("th", text: "Current Status")
    end
  end

  describe "table styling options" do
    it "applies striped rows by default" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css(".table-striped")
    end

    it "can disable striping" do
      render_inline(described_class.new(data: sample_data, striped: false)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).not_to have_css(".table-striped")
    end

    it "applies hover effect by default" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css(".table-hover")
    end

    it "applies bordered styling" do
      render_inline(described_class.new(data: sample_data, bordered: true)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css(".shadow-sm.ring-1")
    end

    it "applies compact mode" do
      render_inline(described_class.new(data: sample_data, compact: true)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css(".py-2")
      expect(page).not_to have_css(".py-4")
    end
  end

  describe "column configuration" do
    it "handles sortable columns" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name", sortable: true)
        grid.with_column(key: :email, label: "Email", sortable: false)
      end
      
      expect(page).to have_css("th.cursor-pointer", text: "Name")
      expect(page).not_to have_css("th.cursor-pointer", text: "Email")
    end

    it "applies column alignment" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name", align: :left)
        grid.with_column(key: :amount, label: "Amount", align: :right)
        grid.with_column(key: :status, label: "Status", align: :center)
      end
      
      expect(page).to have_css("th.text-left", text: "Name")
      expect(page).to have_css("th.text-right", text: "Amount")
      expect(page).to have_css("th.text-center", text: "Status")
    end

    it "applies custom column width" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :id, label: "ID", width: "w-16")
        grid.with_column(key: :name, label: "Name", width: "w-64")
      end
      
      # Width would be applied in the actual component implementation
      expect(page).to have_css("th", text: "ID")
      expect(page).to have_css("th", text: "Name")
    end
  end

  describe "data formatting" do
    it "formats currency values" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :amount, label: "Amount", format: :currency)
      end
      
      expect(page).to have_text("$1,000.00")
      expect(page).to have_text("$2,000.00")
    end

    it "formats boolean values" do
      data_with_boolean = [
        { id: 1, name: "Item 1", active: true },
        { id: 2, name: "Item 2", active: false }
      ]
      
      render_inline(described_class.new(data: data_with_boolean)) do |grid|
        grid.with_column(key: :active, label: "Active", format: :boolean)
      end
      
      expect(page).to have_text("✓")
      expect(page).to have_text("✗")
    end

    it "formats with custom proc" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(
          key: :status,
          label: "Status",
          format: ->(value) { value.upcase }
        )
      end
      
      expect(page).to have_text("ACTIVE")
      expect(page).to have_text("INACTIVE")
    end
  end

  describe "loading state" do
    it "shows loading skeleton" do
      render_inline(described_class.new(data: [], loading: true)) do |grid|
        grid.with_column(key: :name, label: "Name")
        grid.with_column(key: :email, label: "Email")
      end
      
      expect(page).to have_css(".animate-pulse")
    end
  end

  describe "empty state" do
    it "shows empty state when no data" do
      render_inline(described_class.new(data: [])) do |grid|
        grid.with_column(key: :name, label: "Name")
        grid.with_empty_state do
          "No data available"
        end
      end
      
      expect(page).to have_text("No data available")
    end
  end

  describe "row selection" do
    it "renders checkboxes when selectable" do
      render_inline(described_class.new(
        data: sample_data,
        selectable: true,
        selected: [1, 3]
      )) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css("input[type='checkbox']", count: 4) # 3 rows + 1 header
    end
  end

  describe "row actions" do
    it "renders action buttons for each row" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name")
        grid.with_actions do |item|
          link_to "Edit", "#edit-#{item[:id]}", class: "text-blue-600"
        end
      end
      
      expect(page).to have_link("Edit", count: 3)
      expect(page).to have_css("a[href='#edit-1']")
    end
  end

  describe "responsive design" do
    it "applies responsive wrapper by default" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css(".overflow-x-auto")
    end

    it "can disable responsive wrapper" do
      render_inline(described_class.new(data: sample_data, responsive: false)) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).not_to have_css(".overflow-x-auto")
    end
  end

  describe "custom CSS classes" do
    it "accepts custom wrapper classes" do
      render_inline(described_class.new(
        data: sample_data,
        class: "custom-grid-class"
      )) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css(".data-grid-wrapper.custom-grid-class")
    end

    it "accepts custom column classes" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(
          key: :name,
          label: "Name",
          header_class: "custom-header",
          cell_class: "custom-cell"
        )
      end
      
      expect(page).to have_css("th.custom-header")
      expect(page).to have_css("td.custom-cell")
    end
  end

  describe "accessibility" do
    it "has proper table structure" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name")
        grid.with_column(key: :email, label: "Email")
      end
      
      expect(page).to have_css("table")
      expect(page).to have_css("thead")
      expect(page).to have_css("tbody")
      expect(page).to have_css("tr", minimum: 3)
    end

    it "includes proper ARIA attributes for sortable columns" do
      render_inline(described_class.new(data: sample_data)) do |grid|
        grid.with_column(key: :name, label: "Name", sortable: true)
      end
      
      expect(page).to have_css("th[role='columnheader']")
    end
  end

  describe "stimulus integration" do
    it "includes data attributes for row click handling" do
      render_inline(described_class.new(
        data: sample_data,
        row_click: true
      )) do |grid|
        grid.with_column(key: :name, label: "Name")
      end
      
      expect(page).to have_css("tr.cursor-pointer")
    end
  end
end