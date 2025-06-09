require 'rails_helper'

RSpec.describe Ui::DataGridComponent::HeaderCellComponent, type: :component do
  let(:column) do
    Ui::DataGridComponent::ColumnComponent.new(
      key: :name,
      label: "Name",
      sortable: false
    )
  end

  describe "basic rendering" do
    it "renders header cell with label" do
      render_inline(described_class.new(column: column))
      
      expect(page).to have_css("th[scope='col']")
      expect(page).to have_text("Name")
    end

    it "includes role attribute for accessibility" do
      render_inline(described_class.new(column: column))
      
      expect(page).to have_css("th[role='columnheader']")
    end

    it "applies default styling classes" do
      render_inline(described_class.new(column: column))
      
      expect(page).to have_css("th.px-6.py-3.text-xs.font-medium.text-gray-500.uppercase.tracking-wider")
    end
  end

  describe "alignment" do
    it "applies left alignment by default" do
      render_inline(described_class.new(column: column))
      
      expect(page).to have_css("th.text-left")
      expect(page).to have_css("div.flex.items-center")
      expect(page).not_to have_css("div.justify-center")
      expect(page).not_to have_css("div.justify-end")
    end

    it "applies center alignment" do
      centered_column = Ui::DataGridComponent::ColumnComponent.new(
        key: :status,
        label: "Status",
        align: :center
      )
      
      render_inline(described_class.new(column: centered_column))
      
      expect(page).to have_css("th.text-center")
      expect(page).to have_css("div.justify-center")
    end

    it "applies right alignment" do
      right_column = Ui::DataGridComponent::ColumnComponent.new(
        key: :amount,
        label: "Amount",
        align: :right
      )
      
      render_inline(described_class.new(column: right_column))
      
      expect(page).to have_css("th.text-right")
      expect(page).to have_css("div.justify-end")
    end
  end

  describe "width" do
    it "applies custom width when specified" do
      column_with_width = Ui::DataGridComponent::ColumnComponent.new(
        key: :id,
        label: "ID",
        width: "w-16"
      )
      
      render_inline(described_class.new(column: column_with_width))
      
      expect(page).to have_css("th[style='width: w-16']")
    end

    it "does not apply width style when not specified" do
      render_inline(described_class.new(column: column))
      
      expect(page).not_to have_css("th[style]")
    end
  end

  describe "custom classes" do
    it "applies custom header class" do
      custom_column = Ui::DataGridComponent::ColumnComponent.new(
        key: :name,
        label: "Name",
        header_class: "custom-header-class"
      )
      
      render_inline(described_class.new(column: custom_column))
      
      expect(page).to have_css("th.custom-header-class")
    end
  end

  describe "sortable columns" do
    let(:sortable_column) do
      Ui::DataGridComponent::ColumnComponent.new(
        key: :name,
        label: "Name",
        sortable: true
      )
    end

    it "adds sortable styling for sortable columns" do
      render_inline(described_class.new(column: sortable_column))
      
      expect(page).to have_css("th.cursor-pointer.select-none.hover\\:text-gray-700")
    end

    it "adds data attributes for sorting" do
      render_inline(described_class.new(column: sortable_column))
      
      expect(page).to have_css("th[data-sortable='true']")
      expect(page).to have_css("th[data-sort-key='name']")
      expect(page).to have_css("th[data-action='click->data-grid#sort']")
    end

    it "shows neutral sort indicator for sortable columns" do
      render_inline(described_class.new(column: sortable_column))
      
      expect(page).to have_css("svg.ml-1.h-4.w-4.text-gray-400")
      expect(page).to have_css("path[d*='M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4']")
    end

    it "does not show sort indicator for non-sortable columns" do
      render_inline(described_class.new(column: column))
      
      expect(page).not_to have_css("svg")
    end

    it "does not add data attributes for non-sortable columns" do
      render_inline(described_class.new(column: column))
      
      expect(page).not_to have_css("th[data-sortable]")
      expect(page).not_to have_css("th[data-sort-key]")
      expect(page).not_to have_css("th[data-action]")
    end
  end

  describe "current sort state" do
    let(:sortable_column) do
      Ui::DataGridComponent::ColumnComponent.new(
        key: :name,
        label: "Name",
        sortable: true
      )
    end

    it "shows ascending arrow when column is sorted ascending" do
      render_inline(described_class.new(
        column: sortable_column,
        current_sort_key: "name",
        current_sort_direction: "asc"
      ))
      
      expect(page).to have_css("svg.ml-1.h-4.w-4.text-gray-600")
      expect(page).to have_css("path[d='M5 15l7-7 7 7']")
      expect(page).not_to have_css("svg.text-gray-400")
    end

    it "shows descending arrow when column is sorted descending" do
      render_inline(described_class.new(
        column: sortable_column,
        current_sort_key: "name",
        current_sort_direction: "desc"
      ))
      
      expect(page).to have_css("svg.ml-1.h-4.w-4.text-gray-600")
      expect(page).to have_css("path[d='M19 9l-7 7-7-7']")
      expect(page).not_to have_css("svg.text-gray-400")
    end

    it "shows neutral indicator when different column is sorted" do
      render_inline(described_class.new(
        column: sortable_column,
        current_sort_key: "email",
        current_sort_direction: "asc"
      ))
      
      expect(page).to have_css("svg.ml-1.h-4.w-4.text-gray-400")
      expect(page).not_to have_css("svg.text-gray-600")
    end

    it "handles symbol vs string key comparison" do
      render_inline(described_class.new(
        column: sortable_column,
        current_sort_key: :name,
        current_sort_direction: "asc"
      ))
      
      expect(page).to have_css("svg.ml-1.h-4.w-4.text-gray-600")
      expect(page).to have_css("path[d='M5 15l7-7 7 7']")
    end
  end

  describe "real-world usage" do
    it "renders non-sortable column correctly" do
      actions_column = Ui::DataGridComponent::ColumnComponent.new(
        key: :actions,
        label: "",
        sortable: false,
        align: :right,
        width: "w-20"
      )
      
      render_inline(described_class.new(column: actions_column))
      
      expect(page).to have_css("th.text-right")
      expect(page).to have_css("th[style='width: w-20']")
      expect(page).not_to have_css("th.cursor-pointer")
      expect(page).not_to have_css("svg")
    end

    it "renders sortable column with custom styling" do
      custom_column = Ui::DataGridComponent::ColumnComponent.new(
        key: :created_at,
        label: "Date Created",
        sortable: true,
        align: :center,
        header_class: "bg-gray-100"
      )
      
      render_inline(described_class.new(
        column: custom_column,
        current_sort_key: "created_at",
        current_sort_direction: "desc"
      ))
      
      expect(page).to have_css("th.text-center.bg-gray-100.cursor-pointer")
      expect(page).to have_text("Date Created")
      expect(page).to have_css("svg.text-gray-600") # Descending arrow
    end
  end
end