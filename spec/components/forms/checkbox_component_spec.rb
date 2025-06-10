require 'rails_helper'

RSpec.describe Forms::CheckboxComponent, type: :component do
  let(:form) { setup_form_builder(agree: false) }
  let(:attribute) { :agree }
  let(:options) { {} }
  let(:component) { described_class.new(form: form, attribute: attribute, **options) }
  
  before do
    mock_component_helpers(described_class)
  end

  describe 'inheritance' do
    it 'inherits from Forms::FieldComponent' do
      expect(described_class.superclass).to eq Forms::FieldComponent
    end
  end

  describe '#render' do
    it 'renders checkbox input' do
      render_inline(component)
      puts page.native.to_s # Debug output
      expect(page).to have_css('input[type="checkbox"]')
    end

    it 'renders with custom label structure' do
      render_inline(component)
      expect(page).to have_css('.flex.items-start')
      expect(page).to have_css('.flex.items-center.h-5')
    end

    context 'with default label' do
      it 'humanizes attribute name' do
        render_inline(component)
        expect(page).to have_text('Agree')
      end
    end

    context 'with custom label' do
      let(:options) { { label_text: 'I agree to the terms and conditions' } }

      it 'uses custom label text' do
        render_inline(component)
        expect(page).to have_text('I agree to the terms and conditions')
      end
    end

    context 'when checked' do
      let(:options) { { checked: true } }

      it 'renders as checked' do
        render_inline(component)
        expect(page).to have_css('input[type="checkbox"][checked]')
      end
    end

    context 'with hint text' do
      let(:options) { { hint: 'This is required to continue' } }

      it 'renders hint below label' do
        render_inline(component)
        expect(page).to have_text('This is required to continue')
        expect(page).to have_css('.text-sm.text-gray-500')
      end
    end

    context 'with errors' do
      before do
        form.object.errors.add(:agree, 'must be accepted')
      end

      it 'shows error message' do
        render_inline(component)
        expect(page).to have_text('must be accepted')
      end

      it 'applies error styling' do
        render_inline(component)
        expect(page).to have_css('input.border-red-300')
      end
    end

    context 'when required' do
      let(:options) { { required: true } }

      it 'adds required attribute' do
        render_inline(component)
        expect(page).to have_css('input[required]')
      end
    end
  end

  describe '#should_render_label?' do
    it 'returns false' do
      expect(component.send(:should_render_label?)).to be false
    end
  end

  describe 'styling' do
    it 'applies Tailwind checkbox styles' do
      render_inline(component)
      expect(page).to have_css('input.h-4.w-4.rounded.border-gray-300.text-indigo-600')
      expect(page).to have_css('input.focus\\:ring-indigo-500')
    end

    it 'has proper label styling' do
      render_inline(component)
      expect(page).to have_css('label.text-sm.font-medium.text-gray-700')
    end
  end
end