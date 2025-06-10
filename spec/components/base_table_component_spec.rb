require 'rails_helper'

RSpec.describe BaseTableComponent, type: :component do
  let(:items) { [] }
  let(:columns) { [] }
  let(:options) { {} }
  let(:component) { described_class.new(items: items, columns: columns, **options) }

  describe '#initialize' do
    it 'sets default options' do
      expect(component.instance_variable_get(:@striped)).to be true
      expect(component.instance_variable_get(:@bordered)).to be true
      expect(component.instance_variable_get(:@hoverable)).to be true
      expect(component.instance_variable_get(:@responsive)).to be true
      expect(component.instance_variable_get(:@selectable)).to be false
    end

    context 'with custom options' do
      let(:options) { { striped: false, selectable: true, empty_message: 'No records' } }

      it 'overrides defaults' do
        expect(component.instance_variable_get(:@striped)).to be false
        expect(component.instance_variable_get(:@selectable)).to be true
        expect(component.instance_variable_get(:@empty_message)).to eq 'No records'
      end
    end
  end

  describe '#render' do
    context 'with empty items' do
      it 'renders empty state' do
        render_inline(component)
        expect(page).to have_text('No data available')
      end
    end

    context 'with items' do
      let(:items) { [OpenStruct.new(id: 1, name: 'Item 1'), OpenStruct.new(id: 2, name: 'Item 2')] }
      let(:columns) { [{ key: :id, label: 'ID' }, { key: :name, label: 'Name' }] }

      it 'renders table with items' do
        render_inline(component)
        expect(page).to have_css('table')
        expect(page).to have_text('Item 1')
        expect(page).to have_text('Item 2')
      end
    end

    context 'with selectable option' do
      let(:options) { { selectable: true } }
      let(:items) { [OpenStruct.new(id: 1, name: 'Item 1')] }
      let(:columns) { [{ key: :name, label: 'Name' }] }

      it 'renders checkboxes' do
        render_inline(component)
        expect(page).to have_css('input[type="checkbox"]', count: 2) # header + row
      end
    end
  end

  describe 'protected methods' do
    describe '#table_classes' do
      it 'returns base classes' do
        classes = component.send(:table_classes)
        expect(classes).to include('min-w-full')
        expect(classes).to include('divide-y')
      end

      context 'with striped option' do
        let(:options) { { striped: true } }

        it 'includes striped class' do
          classes = component.send(:table_classes)
          expect(classes).to include('striped')
        end
      end
    end

    describe '#header_cell_classes' do
      let(:column) { { key: :name, class: 'custom-class' } }

      it 'includes base and custom classes' do
        classes = component.send(:header_cell_classes, column)
        expect(classes).to include('px-6')
        expect(classes).to include('py-3')
        expect(classes).to include('custom-class')
      end
    end

    describe '#row_classes' do
      let(:item) { OpenStruct.new(id: 1) }

      context 'with hoverable option' do
        let(:options) { { hoverable: true } }

        it 'includes hover class' do
          classes = component.send(:row_classes, item, 0)
          expect(classes).to include('hover:bg-gray-100')
        end
      end

      context 'with striped option on odd row' do
        let(:options) { { striped: true } }

        it 'includes striped background' do
          classes = component.send(:row_classes, item, 1)
          expect(classes).to include('bg-gray-50')
        end
      end
    end
  end
end