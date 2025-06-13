require 'rails_helper'

RSpec.describe Forms::FieldComponent, type: :component do
  # Create a concrete implementation for testing
  let(:test_field_class) do
    Class.new(described_class) do
      def self.name
        "TestFieldComponent"
      end
      
      def render_field
        helpers.content_tag :input, nil, 
                           type: 'text',
                           name: "#{@form.object_name}[#{@attribute}]",
                           id: field_id,
                           class: field_classes,
                           value: @form.object.public_send(@attribute)
      end
    end
  end
  
  let(:form) { setup_form_builder(name: 'Test') }
  let(:attribute) { :name }
  let(:options) { {} }
  let(:component) { test_field_class.new(form: form, attribute: attribute, **options) }
  
  before do
    mock_component_helpers(test_field_class)
  end

  describe '#render' do
    it 'renders wrapper div' do
      render_inline(component)
      expect(page).to have_css('div.mb-4')
    end

    it 'renders label by default' do
      render_inline(component)
      expect(page).to have_css('label', text: 'Name')
    end

    context 'with custom wrapper class' do
      let(:options) { { wrapper_class: 'custom-wrapper' } }

      it 'uses custom wrapper class' do
        render_inline(component)
        expect(page).to have_css('div.custom-wrapper')
      end
    end

    context 'with inline layout' do
      let(:options) { { layout: :inline } }

      it 'renders with flex layout' do
        render_inline(component)
        expect(page).to have_css('.flex.items-start.space-x-4')
      end

      it 'applies inline label classes' do
        render_inline(component)
        expect(page).to have_css('label.flex-shrink-0.w-1\\/3.pt-2')
      end
    end

    context 'with stacked layout' do
      let(:options) { { layout: :stacked } }

      it 'renders with block layout' do
        render_inline(component)
        expect(page).not_to have_css('.flex.items-start')
        expect(page).to have_css('label.block.mb-1')
      end
    end

    context 'with custom label' do
      let(:options) { { label: 'Full Name' } }

      it 'uses custom label' do
        render_inline(component)
        expect(page).to have_text('Full Name')
      end
    end

    context 'with hint' do
      let(:options) { { hint: 'Enter your full name' } }

      it 'renders hint text' do
        render_inline(component)
        expect(page).to have_text('Enter your full name')
        expect(page).to have_css('p.mt-1.text-sm.text-gray-500')
      end
    end

    context 'when required' do
      let(:options) { { required: true } }

      it 'shows asterisk in label' do
        render_inline(component)
        expect(page).to have_text('Name *')
      end
    end

    context 'with errors' do
      before do
        form.object.errors.add(:name, 'is invalid')
        form.object.errors.add(:name, 'is too short')
      end

      it 'shows all error messages' do
        render_inline(component)
        expect(page).to have_text('is invalid, is too short')
      end

      it 'renders error paragraph' do
        render_inline(component)
        expect(page).to have_css('p.mt-1.text-sm.text-red-600')
      end
    end
  end

  describe '#render_field' do
    it 'raises NotImplementedError in base class' do
      base_component = described_class.new(form: form, attribute: attribute)
      expect { base_component.send(:render_field) }.to raise_error(NotImplementedError)
    end
  end

  describe 'protected methods' do
    describe '#label_classes' do
      it 'returns standard label classes for stacked layout' do
        expect(component.send(:label_classes)).to eq 'text-sm font-medium text-gray-700 block mb-1'
      end

      context 'with inline layout' do
        let(:options) { { layout: :inline } }

        it 'returns inline label classes' do
          expect(component.send(:label_classes)).to eq 'text-sm font-medium text-gray-700 flex-shrink-0 w-1/3 pt-2'
        end
      end
    end

    describe '#field_classes' do
      it 'returns base field classes' do
        classes = component.send(:field_classes)
        expect(classes).to include('block w-full rounded-md shadow-sm')
        expect(classes).to include('border-gray-300')
        expect(classes).to include('focus:border-indigo-500')
      end

      context 'with errors' do
        before { form.object.errors.add(:name, 'is invalid') }

        it 'includes error classes' do
          classes = component.send(:field_classes)
          expect(classes).to include('border-red-300')
          expect(classes).to include('text-red-900')
          expect(classes).to include('placeholder-red-300')
        end
      end

      context 'with custom class' do
        let(:options) { { class: 'custom-field-class' } }

        it 'appends custom class' do
          classes = component.send(:field_classes)
          expect(classes).to include('custom-field-class')
        end
      end
    end

    describe '#field_id' do
      it 'generates proper field ID' do
        expect(component.send(:field_id)).to eq 'test_model_name'
      end

      context 'with nested attributes' do
        let(:form) { setup_form_builder(name: 'Test') }
        before do
          allow(form).to receive(:object_name).and_return('user[address]')
        end

        it 'handles brackets correctly' do
          expect(component.send(:field_id)).to eq 'user_address_name'
        end
      end
    end

    describe '#hint_id' do
      it 'generates hint ID' do
        expect(component.send(:hint_id)).to eq 'test_model_name_hint'
      end
    end

    describe '#error_id' do
      it 'generates error ID' do
        expect(component.send(:error_id)).to eq 'test_model_name_error'
      end
    end

    describe '#aria_describedby' do
      context 'with no hint or errors' do
        it 'returns nil' do
          expect(component.send(:aria_describedby)).to be_nil
        end
      end

      context 'with hint only' do
        let(:options) { { hint: 'Help text' } }

        it 'returns hint ID' do
          expect(component.send(:aria_describedby)).to eq 'test_model_name_hint'
        end
      end

      context 'with errors only' do
        before { form.object.errors.add(:name, 'is invalid') }

        it 'returns error ID' do
          expect(component.send(:aria_describedby)).to eq 'test_model_name_error'
        end
      end

      context 'with both hint and errors' do
        let(:options) { { hint: 'Help text' } }
        before { form.object.errors.add(:name, 'is invalid') }

        it 'returns both IDs' do
          expect(component.send(:aria_describedby)).to eq 'test_model_name_hint test_model_name_error'
        end
      end
    end

    describe '#field_options' do
      it 'includes field ID' do
        opts = component.send(:field_options)
        expect(opts[:id]).to eq 'test_model_name'
      end

      context 'when required' do
        let(:options) { { required: true } }

        it 'adds required attribute' do
          opts = component.send(:field_options)
          expect(opts[:required]).to be true
        end
      end

      context 'with ARIA attributes' do
        let(:options) { { hint: 'Help' } }
        before { form.object.errors.add(:name, 'error') }

        it 'adds aria-describedby' do
          opts = component.send(:field_options)
          expect(opts[:aria][:describedby]).to be_present
        end

        it 'adds aria-invalid' do
          opts = component.send(:field_options)
          expect(opts[:aria][:invalid]).to be true
        end
      end
    end
  end
end