require 'rails_helper'

RSpec.describe Ui::DataTableComponent, type: :component do
  before do
    mock_component_helpers(described_class)
  end
  
  context "basic table wrapper mode" do
    it "renders responsive wrapper" do
      rendered = render_inline(described_class.new) do
        '<table><tr><td>Cell content</td></tr></table>'.html_safe
      end
      
      expect(rendered).to have_css('.overflow-x-auto')
      expect(rendered).to have_css('table')
      expect(rendered).to have_text('Cell content')
    end

    it "renders without responsive wrapper when disabled" do
      rendered = render_inline(described_class.new(responsive: false)) do
        '<table><tr><td>Cell content</td></tr></table>'.html_safe
      end
      
      expect(rendered).not_to have_css('.overflow-x-auto')
      expect(rendered).to have_css('table')
    end
  end

  context "advanced table mode" do
    let(:items) do
      [
        { id: 1, name: 'Item 1', status: 'active', progress: 75 },
        { id: 2, name: 'Item 2', status: 'inactive', progress: 30 }
      ]
    end

    let(:columns) do
      [
        { key: :name, label: 'Name' },
        { key: :status, label: 'Status', type: :status },
        { key: :progress, label: 'Progress', type: :progress }
      ]
    end

    it "renders table with items and columns" do
      rendered = render_inline(described_class.new(items: items, columns: columns))
      
      expect(rendered).to have_css('table')
      expect(rendered).to have_css('thead th', count: 3)
      expect(rendered).to have_css('tbody tr', count: 2)
      expect(rendered).to have_text('Item 1')
      expect(rendered).to have_text('Item 2')
    end

    it "renders empty state when no items" do
      rendered = render_inline(described_class.new(
        items: [], 
        columns: columns,
        empty_message: 'No data found'
      ))
      
      expect(rendered).to have_text('No data found')
      expect(rendered).not_to have_css('table')
    end

    it "applies striped styling" do
      rendered = render_inline(described_class.new(
        items: items,
        columns: columns,
        striped: true
      ))
      
      expect(rendered).to have_css('.table-striped')
    end

    it "applies hoverable styling" do
      rendered = render_inline(described_class.new(
        items: items,
        columns: columns,
        hoverable: true
      ))
      
      expect(rendered).to have_css('.hover\\:bg-gray-50')
    end

    it "renders different cell types" do
      test_date = Date.new(2024, 1, 15)
      complex_items = [{
        name: 'Test',
        status: 'active',
        progress: 60,
        amount: 1500,
        created_at: test_date
      }]
      
      complex_columns = [
        { key: :name, label: 'Name' },
        { key: :status, label: 'Status', type: :status },
        { key: :progress, label: 'Progress', type: :progress },
        { key: :amount, label: 'Amount', type: :money },
        { key: :created_at, label: 'Date', type: :date }
      ]
      
      rendered = render_inline(described_class.new(items: complex_items, columns: complex_columns))
      
      expect(rendered).to have_text('Test')
      # Status badge would be rendered by StatusBadgeComponent
      # Progress bar would be rendered by ProgressBarComponent
      expect(rendered).to have_text('1 500')
      expect(rendered).to have_text('15 jan.')
    end

    it "handles nested attributes with dot notation" do
      nested_items = [{
        user: { name: 'John Doe', email: 'john@example.com' }
      }]
      
      nested_columns = [
        { key: 'user.name', label: 'Name' },
        { key: 'user.email', label: 'Email' }
      ]
      
      rendered = render_inline(described_class.new(items: nested_items, columns: nested_columns))
      
      expect(rendered).to have_text('John Doe')
      expect(rendered).to have_text('john@example.com')
    end

    it "handles proc keys" do
      proc_columns = [
        { key: ->(item) { item[:name].upcase }, label: 'Uppercase Name' }
      ]
      
      rendered = render_inline(described_class.new(items: items, columns: proc_columns))
      
      expect(rendered).to have_text('ITEM 1')
      expect(rendered).to have_text('ITEM 2')
    end
  end
end