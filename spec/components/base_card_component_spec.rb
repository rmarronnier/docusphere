require 'rails_helper'

RSpec.describe BaseCardComponent, type: :component do
  let(:component) { described_class.new }

  describe '#initialize' do
    it 'sets default options' do
      expect(component.instance_variable_get(:@padding)).to be true
      expect(component.instance_variable_get(:@shadow)).to be true
      expect(component.instance_variable_get(:@rounded)).to be true
      expect(component.instance_variable_get(:@hover)).to be false
      expect(component.instance_variable_get(:@border)).to be false
    end

    it 'accepts custom options' do
      component = described_class.new(padding: false, shadow: false, hover: true, border: true)
      expect(component.instance_variable_get(:@padding)).to be false
      expect(component.instance_variable_get(:@shadow)).to be false
      expect(component.instance_variable_get(:@hover)).to be true
      expect(component.instance_variable_get(:@border)).to be true
    end
  end

  describe '#card_classes' do
    it 'includes base classes' do
      classes = component.send(:card_classes)
      expect(classes).to include('bg-white')
    end

    it 'includes padding class when padding is true' do
      component = described_class.new(padding: true)
      classes = component.send(:card_classes)
      expect(classes).to include('p-6')
    end

    it 'excludes padding class when padding is false' do
      component = described_class.new(padding: false)
      classes = component.send(:card_classes)
      expect(classes).not_to include('p-6')
    end

    it 'includes shadow class when shadow is true' do
      component = described_class.new(shadow: true)
      classes = component.send(:card_classes)
      expect(classes).to include('shadow')
    end

    it 'excludes shadow class when shadow is false' do
      component = described_class.new(shadow: false)
      classes = component.send(:card_classes)
      expect(classes).not_to include('shadow')
    end

    it 'includes rounded class when rounded is true' do
      component = described_class.new(rounded: true)
      classes = component.send(:card_classes)
      expect(classes).to include('rounded-lg')
    end

    it 'excludes rounded class when rounded is false' do
      component = described_class.new(rounded: false)
      classes = component.send(:card_classes)
      expect(classes).not_to include('rounded-lg')
    end

    it 'includes hover classes when hover is true' do
      component = described_class.new(hover: true)
      classes = component.send(:card_classes)
      expect(classes).to include('hover:shadow-lg')
      expect(classes).to include('transition-shadow')
    end

    it 'excludes hover classes when hover is false' do
      component = described_class.new(hover: false)
      classes = component.send(:card_classes)
      expect(classes).not_to include('hover:shadow-lg')
      expect(classes).not_to include('transition-shadow')
    end

    it 'includes border class when border is true' do
      component = described_class.new(border: true)
      classes = component.send(:card_classes)
      expect(classes).to include('border')
      expect(classes).to include('border-gray-200')
    end

    it 'excludes border class when border is false' do
      component = described_class.new(border: false)
      classes = component.send(:card_classes)
      expect(classes).not_to include('border')
    end
  end

  describe '#render_card_header' do
    it 'returns nil when no title or actions provided' do
      result = component.send(:render_card_header)
      expect(result).to be_nil
    end

    it 'renders header with title only' do
      result = component.send(:render_card_header, title: 'Test Title')
      expect(result).to include('Test Title')
      expect(result).to include('text-lg font-medium text-gray-900')
    end

    it 'renders header with actions only' do
      actions = '<button>Action</button>'.html_safe
      result = component.send(:render_card_header, actions: actions)
      expect(result).to include('<button>Action</button>')
      expect(result).to include('flex items-center space-x-2')
    end

    it 'renders header with both title and actions' do
      actions = '<button>Action</button>'.html_safe
      result = component.send(:render_card_header, title: 'Test Title', actions: actions)
      expect(result).to include('Test Title')
      expect(result).to include('<button>Action</button>')
    end
  end

  describe '#render_card_footer' do
    it 'renders footer with content' do
      content = 'Footer content'
      result = component.send(:render_card_footer, content)
      expect(result).to include('Footer content')
      expect(result).to include('mt-6 pt-6 border-t border-gray-200')
    end
  end

  describe '#call' do
    it 'renders a div with card classes' do
      rendered = render_inline(component) { 'Card content' }
      expect(rendered.css('div.bg-white')).to be_present
      expect(rendered.text).to include('Card content')
    end

    it 'applies custom classes based on options' do
      component = described_class.new(border: true, hover: true, shadow: false)
      rendered = render_inline(component) { 'Card content' }
      
      expect(rendered.css('div.border')).to be_present
      expect(rendered.css('div.hover\\:shadow-lg')).to be_present
      expect(rendered.css('div.shadow')).to be_empty
    end
  end

  describe '#render_card_content' do
    it 'returns content by default' do
      component = described_class.new
      allow(component).to receive(:content).and_return('test content')
      expect(component.send(:render_card_content)).to eq('test content')
    end
  end
end