require 'rails_helper'

RSpec.describe Forms::RadioGroupComponent, type: :component do
  let(:form) { setup_form_builder(gender: 'male') }
  let(:attribute) { :gender }
  let(:radio_options) { [['Male', 'male'], ['Female', 'female'], ['Other', 'other']] }
  let(:options) { { options: radio_options } }
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
    it 'renders fieldset' do
      render_inline(component)
      expect(page).to have_css('fieldset')
    end

    it 'renders radio buttons for each option' do
      render_inline(component)
      expect(page).to have_css('input[type="radio"]', count: 3)
    end

    it 'renders labels for each option' do
      render_inline(component)
      expect(page).to have_text('Male')
      expect(page).to have_text('Female')
      expect(page).to have_text('Other')
    end

    context 'with vertical layout (default)' do
      it 'renders legend' do
        render_inline(component)
        expect(page).to have_css('legend', text: 'Gender')
      end

      it 'uses vertical spacing' do
        render_inline(component)
        expect(page).to have_css('.space-y-2')
      end
    end

    context 'with horizontal layout' do
      let(:options) { { options: radio_options, layout: :horizontal } }

      it 'renders label instead of legend' do
        render_inline(component)
        expect(page).not_to have_css('legend')
        expect(page).to have_css('label', text: 'Gender')
      end

      it 'uses horizontal spacing' do
        render_inline(component)
        expect(page).to have_css('.flex.items-center.space-x-4')
      end
    end

    context 'with simple array options' do
      let(:radio_options) { %w[Small Medium Large] }

      it 'uses values as labels' do
        render_inline(component)
        expect(page).to have_text('Small')
        expect(page).to have_text('Medium')
        expect(page).to have_text('Large')
      end

      it 'uses downcased values' do
        render_inline(component)
        expect(page).to have_css('input[value="Small"]')
      end
    end

    context 'with selected value' do
      before { form.object.gender = 'female' }

      it 'checks the correct radio button' do
        render_inline(component)
        expect(page).to have_css('input[type="radio"][value="female"][checked]')
      end
    end

    context 'with custom label' do
      let(:options) { { options: radio_options, label: 'Select Gender' } }

      it 'uses custom label in legend' do
        render_inline(component)
        expect(page).to have_css('legend', text: 'Select Gender')
      end
    end

    context 'with errors' do
      before do
        form.object.errors.add(:gender, 'must be selected')
      end

      it 'shows error message' do
        render_inline(component)
        expect(page).to have_text('must be selected')
      end

      it 'applies error styling to radio buttons' do
        render_inline(component)
        expect(page).to have_css('input.border-red-300', count: 3)
      end
    end

    context 'when required' do
      let(:options) { { options: radio_options, required: true } }

      it 'shows asterisk in legend' do
        render_inline(component)
        expect(page).to have_text('Gender *')
      end
    end
  end

  describe 'accessibility' do
    it 'generates proper field IDs' do
      render_inline(component)
      expect(page).to have_css('input#test_model_gender_male')
      expect(page).to have_css('input#test_model_gender_female')
      expect(page).to have_css('input#test_model_gender_other')
    end

    it 'associates labels with radio buttons' do
      render_inline(component)
      expect(page).to have_css('label[for="test_model_gender_male"]')
      expect(page).to have_css('label[for="test_model_gender_female"]')
      expect(page).to have_css('label[for="test_model_gender_other"]')
    end

    it 'groups radio buttons with same name' do
      render_inline(component)
      expect(page).to have_css('input[name="test_model[gender]"]', count: 3)
    end
  end

  describe 'styling' do
    it 'applies Tailwind radio button styles' do
      render_inline(component)
      expect(page).to have_css('input.h-4.w-4.border-gray-300.text-indigo-600')
      expect(page).to have_css('input.focus\\:ring-indigo-500')
    end

    it 'styles labels appropriately' do
      render_inline(component)
      expect(page).to have_css('label.ml-3.text-sm.font-medium.text-gray-700')
    end

    it 'styles legend appropriately' do
      render_inline(component)
      expect(page).to have_css('legend.text-sm.font-medium.text-gray-700.mb-2')
    end
  end
end