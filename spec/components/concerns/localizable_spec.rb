require 'rails_helper'

RSpec.describe Localizable do
  let(:test_class) do
    Class.new(ApplicationComponent) do
      include Localizable
      
      def self.name
        'TestComponent'
      end
    end
  end
  
  let(:component) { test_class.new }

  describe '#component_t' do
    it 'translates with component scope' do
      expect(I18n).to receive(:t).with('components.test.hello')
      component.component_t('hello')
    end

    it 'passes options to translation' do
      expect(I18n).to receive(:t).with('components.test.greeting', name: 'World')
      component.component_t('greeting', name: 'World')
    end

    context 'with nested component' do
      let(:test_class) do
        Class.new(ApplicationComponent) do
          include Localizable
          
          def self.name
            'Forms::FieldComponent'
          end
        end
      end

      it 'handles nested namespaces' do
        expect(I18n).to receive(:t).with('components.forms.field.label')
        component.component_t('label')
      end
    end
  end

  describe '#translation_exists?' do
    it 'checks if translation exists' do
      expect(I18n).to receive(:exists?).with('components.test.key').and_return(true)
      expect(component.translation_exists?('key')).to be true
    end

    it 'returns false for missing translation' do
      expect(I18n).to receive(:exists?).with('components.test.missing').and_return(false)
      expect(component.translation_exists?('missing')).to be false
    end
  end

  describe '#label_with_fallback' do
    context 'when translation exists' do
      before do
        allow(component).to receive(:translation_exists?).with('status').and_return(true)
        allow(component).to receive(:component_t).with('status').and_return('État')
      end

      it 'returns translated label' do
        expect(component.label_with_fallback('status')).to eq 'État'
      end
    end

    context 'when translation does not exist' do
      before do
        allow(component).to receive(:translation_exists?).with('unknown_key').and_return(false)
      end

      it 'returns humanized key' do
        expect(component.label_with_fallback('unknown_key')).to eq 'Unknown key'
      end

      it 'returns custom fallback if provided' do
        expect(component.label_with_fallback('unknown_key', 'Custom Fallback')).to eq 'Custom Fallback'
      end
    end
  end

  describe '.translatable_attributes' do
    let(:test_class) do
      Class.new(ApplicationComponent) do
        include Localizable
        
        translatable_attributes :status, :type
        
        def initialize(status: nil, type: nil)
          @status = status
          @type = type
        end
        
        def self.name
          'TestComponent'
        end
      end
    end
    
    let(:component) { test_class.new(status: 'active', type: 'primary') }

    describe 'generated label methods' do
      it 'creates label method for each attribute' do
        expect(component).to respond_to(:status_label)
        expect(component).to respond_to(:type_label)
      end

      context 'when translation exists' do
        before do
          allow(component).to receive(:translation_exists?).with('status.active').and_return(true)
          allow(component).to receive(:component_t).with('status.active').and_return('Actif')
        end

        it 'returns translated label' do
          expect(component.status_label).to eq 'Actif'
        end
      end

      context 'when translation does not exist' do
        before do
          allow(component).to receive(:translation_exists?).with('status.active').and_return(false)
        end

        it 'returns humanized value' do
          expect(component.status_label).to eq 'Active'
        end
      end

      context 'when attribute is nil' do
        let(:component) { test_class.new(status: nil) }

        it 'returns nil' do
          expect(component.status_label).to be_nil
        end
      end
    end
  end

  describe 'integration with view helpers' do
    it 'delegates t to helpers' do
      expect(component).to respond_to(:t)
    end

    it 'delegates l to helpers' do
      expect(component).to respond_to(:l)
    end
  end
end