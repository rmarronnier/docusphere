require 'rails_helper'

RSpec.describe BaseListComponent, type: :component do
  let(:view_context) { controller.view_context }
  
  before do
    mock_component_helpers(described_class)
  end
  
  describe '#initialize' do
    context 'with default values' do
      let(:items) { [] }
      let(:component) { described_class.new(items: items) }
      
      it 'sets default empty message' do
        expect(component.instance_variable_get(:@empty_message)).to eq('No items to display')
      end
      
      it 'sets default wrapper class' do
        expect(component.instance_variable_get(:@wrapper_class)).to eq('space-y-4')
      end
    end
    
    context 'with custom values' do
      let(:items) { [] }
      let(:component) do
        described_class.new(
          items: items,
          empty_message: 'Custom empty',
          wrapper_class: 'custom-wrapper'
        )
      end
      
      it 'uses custom empty message' do
        expect(component.instance_variable_get(:@empty_message)).to eq('Custom empty')
      end
      
      it 'uses custom wrapper class' do
        expect(component.instance_variable_get(:@wrapper_class)).to eq('custom-wrapper')
      end
    end
  end
  
  describe '#render' do
    context 'with empty items' do
      let(:items) { [] }
      let(:component) { described_class.new(items: items) }
      
      it 'renders empty state' do
        render_inline(component)
        expect(page).to have_css('div.text-center.py-12')
        expect(page).to have_text('No items to display')
      end
      
      context 'with custom empty message' do
        let(:component) { described_class.new(items: items, empty_message: 'Nothing here') }
        
        it 'uses custom empty message' do
          render_inline(component)
          expect(page).to have_text('Nothing here')
        end
      end
    end
    
    context 'with items' do
      # Create a test subclass that implements render_item
      let(:test_component_class) do
        Class.new(described_class) do
          def self.name
            "TestListComponent"
          end
          
          protected
          
          def render_item(item)
            content_tag :div, item.name, class: 'item'
          end
        end
      end
      
      let(:items) { [OpenStruct.new(name: 'Item 1'), OpenStruct.new(name: 'Item 2')] }
      let(:component) { test_component_class.new(items: items) }
      
      it 'renders wrapper with items' do
        mock_component_helpers(test_component_class)
        render_inline(component)
        expect(page).to have_css('div.space-y-4')
        expect(page).to have_css('div.item', count: 2)
        expect(page).to have_text('Item 1')
        expect(page).to have_text('Item 2')
      end
      
      context 'with custom wrapper class' do
        let(:component) { test_component_class.new(items: items, wrapper_class: 'custom-list') }
        
        it 'uses custom wrapper class' do
          mock_component_helpers(test_component_class)
          render_inline(component)
          expect(page).to have_css('div.custom-list')
        end
      end
    end
  end
  
  describe '#render_item' do
    let(:component) { described_class.new(items: []) }
    
    it 'raises NotImplementedError' do
      expect { component.send(:render_item, Object.new) }.to raise_error(NotImplementedError)
    end
  end
  
  describe 'protected methods' do
    let(:component) { described_class.new(items: []) }
    
    describe '#default_empty_message' do
      it 'returns default message' do
        expect(component.send(:default_empty_message)).to eq('No items to display')
      end
    end
    
    describe '#default_wrapper_class' do
      it 'returns default class' do
        expect(component.send(:default_wrapper_class)).to eq('space-y-4')
      end
    end
    
    describe '#render_empty_state' do
      it 'returns empty state HTML' do
        result = component.send(:render_empty_state)
        expect(result).to include('text-center py-12')
        expect(result).to include('No items to display')
      end
    end
  end
  
  describe 'as abstract base class' do
    it 'is designed to be subclassed' do
      component = described_class.new(items: [])
      expect { render_inline(component) }.not_to raise_error
    end
    
    it 'requires subclasses to implement render_item' do
      component = described_class.new(items: [OpenStruct.new])
      expect { component.send(:render_item, OpenStruct.new) }.to raise_error(NotImplementedError)
    end
  end
end