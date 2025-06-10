require 'rails_helper'

RSpec.describe BaseModalComponent, type: :component do
  before do
    mock_component_helpers(described_class)
  end
  
  describe '#initialize' do
    context 'with required parameters' do
      let(:component) { described_class.new(id: 'test-modal') }
      
      it 'sets the id' do
        expect(component.instance_variable_get(:@id)).to eq('test-modal')
      end
      
      it 'sets default values' do
        expect(component.instance_variable_get(:@title)).to be_nil
        expect(component.instance_variable_get(:@size)).to eq(:medium)
        expect(component.instance_variable_get(:@dismissible)).to be true
      end
    end
    
    context 'with custom parameters' do
      let(:component) do
        described_class.new(
          id: 'custom-modal',
          title: 'Custom Title',
          size: :large,
          dismissible: false
        )
      end
      
      it 'sets all custom values' do
        expect(component.instance_variable_get(:@id)).to eq('custom-modal')
        expect(component.instance_variable_get(:@title)).to eq('Custom Title')
        expect(component.instance_variable_get(:@size)).to eq(:large)
        expect(component.instance_variable_get(:@dismissible)).to be false
      end
    end
  end
  
  describe '#render' do
    let(:component) { described_class.new(id: 'test-modal') }
    
    it 'renders modal container' do
      render_inline(component)
      expect(page).to have_css('div#test-modal[role="dialog"][aria-modal="true"]')
      expect(page).to have_css('div#test-modal.hidden.fixed.inset-0.z-50.overflow-y-auto')
    end
    
    it 'renders backdrop' do
      render_inline(component)
      expect(page).to have_css('div.fixed.inset-0.bg-gray-500.bg-opacity-75')
    end
    
    context 'with title' do
      let(:component) { described_class.new(id: 'test-modal', title: 'Modal Title') }
      
      it 'renders modal header with title' do
        render_inline(component)
        expect(page).to have_css('h3#test-modal-title', text: 'Modal Title')
        expect(page).to have_css('[aria-labelledby="test-modal-title"]')
      end
    end
    
    context 'with dismissible true' do
      let(:component) { described_class.new(id: 'test-modal', dismissible: true) }
      
      it 'renders close button' do
        render_inline(component)
        expect(page).to have_css('button[data-action="click->modal#close"]')
        expect(page).to have_css('.sr-only', text: 'Close')
      end
      
      it 'makes backdrop clickable' do
        render_inline(component)
        expect(page).to have_css('div[data-action="click->modal#close"][aria-hidden="true"]')
      end
    end
    
    context 'with dismissible false' do
      let(:component) { described_class.new(id: 'test-modal', dismissible: false) }
      
      it 'does not render close button' do
        render_inline(component)
        expect(page).not_to have_css('button[data-action="click->modal#close"]')
      end
      
      it 'backdrop is not clickable' do
        render_inline(component)
        expect(page).not_to have_css('div[data-action="click->modal#close"][aria-hidden="true"]')
      end
    end
    
    context 'with different sizes' do
      it 'applies small size class' do
        component = described_class.new(id: 'test-modal', size: :small)
        render_inline(component)
        expect(page).to have_css('div.sm\\:max-w-sm')
      end
      
      it 'applies medium size class' do
        component = described_class.new(id: 'test-modal', size: :medium)
        render_inline(component)
        expect(page).to have_css('div.sm\\:max-w-lg')
      end
      
      it 'applies large size class' do
        component = described_class.new(id: 'test-modal', size: :large)
        render_inline(component)
        expect(page).to have_css('div.sm\\:max-w-3xl')
      end
      
      it 'applies xlarge size class' do
        component = described_class.new(id: 'test-modal', size: :xlarge)
        render_inline(component)
        expect(page).to have_css('div.sm\\:max-w-5xl')
      end
    end
  end
  
  describe 'protected methods' do
    let(:component) { described_class.new(id: 'test-modal') }
    
    describe '#modal_panel_classes' do
      it 'returns base classes with size' do
        expect(component.send(:modal_panel_classes)).to include('relative transform')
        expect(component.send(:modal_panel_classes)).to include('sm:max-w-lg')
      end
    end
    
    describe '#has_footer?' do
      it 'returns false by default' do
        expect(component.send(:has_footer?)).to be false
      end
    end
  end
  
  describe 'with custom content' do
    # Create a test subclass that overrides content methods
    let(:test_modal_class) do
      Class.new(described_class) do
        def self.name
          "TestModalComponent"
        end
        
        protected
        
        def render_body_content
          content_tag :p, 'Custom body content'
        end
        
        def render_footer_content
          content_tag :button, 'OK', class: 'btn btn-primary'
        end
        
        def has_footer?
          true
        end
      end
    end
    
    let(:component) { test_modal_class.new(id: 'test-modal', title: 'Test Modal') }
    
    before do
      mock_component_helpers(test_modal_class)
    end
    
    it 'renders custom body content' do
      render_inline(component)
      expect(page).to have_text('Custom body content')
    end
    
    it 'renders footer when has_footer? is true' do
      render_inline(component)
      expect(page).to have_css('div.bg-gray-50')
      expect(page).to have_button('OK')
    end
  end
  
  describe 'as abstract base class' do
    it 'is designed to be subclassed' do
      component = described_class.new(id: 'test-modal')
      expect { render_inline(component) }.not_to raise_error
    end
    
    it 'provides default render_body_content that uses content' do
      component = described_class.new(id: 'test-modal')
      expect(component.send(:render_body_content)).to eq(component.content)
    end
    
    it 'provides default render_footer_content that returns nil' do
      component = described_class.new(id: 'test-modal')
      expect(component.send(:render_footer_content)).to be_nil
    end
  end
end