require 'rails_helper'

RSpec.describe ComponentsHelper, type: :helper do
  describe '#component' do
    it 'renders a ViewComponent' do
      result = helper.component('ui/button', text: 'Click me')
      expect(result).to be_present
    end
    
    it 'handles component with block' do
      result = helper.component('ui/card') do
        'Card content'
      end
      expect(result).to include('Card content')
    end
  end
  
  describe '#render_component' do
    it 'renders component with attributes' do
      component = UI::ButtonComponent.new(text: 'Submit', variant: 'primary')
      result = helper.render_component(component)
      
      expect(result).to be_present
    end
  end
  
  describe '#component_classes' do
    it 'merges CSS classes' do
      result = helper.component_classes('btn', 'btn-primary', active: true)
      expect(result).to eq('btn btn-primary active')
    end
    
    it 'handles conditional classes' do
      result = helper.component_classes('btn', { 'btn-active': true, 'btn-disabled': false })
      expect(result).to eq('btn btn-active')
    end
  end
  
  describe '#component_attributes' do
    it 'filters and formats attributes for components' do
      attrs = helper.component_attributes(
        id: 'test',
        class: 'btn',
        data: { confirm: 'Are you sure?' },
        internal_option: 'ignored'
      )
      
      expect(attrs).to include(:id, :class, :data)
      expect(attrs).not_to include(:internal_option)
    end
  end
  
  describe '#icon_component' do
    it 'renders icon component shorthand' do
      result = helper.icon_component('document', size: 'large')
      expect(result).to have_css('.icon-document.icon-large')
    end
  end
  
  describe '#button_component' do
    it 'renders button component shorthand' do
      result = helper.button_component('Submit', variant: 'primary', icon: 'check')
      expect(result).to have_css('.btn.btn-primary')
      expect(result).to have_content('Submit')
    end
  end
  
  describe '#card_component' do
    it 'renders card with options' do
      result = helper.card_component(title: 'Test Card') do
        'Card body'
      end
      
      expect(result).to have_css('.card')
      expect(result).to have_content('Test Card')
      expect(result).to have_content('Card body')
    end
  end
  
  describe '#modal_component' do
    it 'renders modal component' do
      result = helper.modal_component(id: 'test-modal', title: 'Confirm') do
        'Modal content'
      end
      
      expect(result).to have_css('#test-modal.modal')
      expect(result).to have_content('Confirm')
    end
  end
  
  describe '#alert_component' do
    it 'renders alert with type' do
      result = helper.alert_component('Success!', type: 'success', dismissible: true)
      
      expect(result).to have_css('.alert.alert-success')
      expect(result).to have_css('.alert-dismiss')
    end
  end
  
  describe '#loading_component' do
    it 'renders loading indicator' do
      result = helper.loading_component(text: 'Loading...')
      
      expect(result).to have_css('.loading')
      expect(result).to have_content('Loading...')
    end
  end
end