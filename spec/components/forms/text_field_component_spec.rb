require 'rails_helper'

RSpec.describe Forms::TextFieldComponent, type: :component do
  let(:form) { setup_form_builder(email: 'test@example.com') }
  let(:attribute) { :email }
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

  describe '#render_field' do
    context 'with default text type' do
      it 'renders text field' do
        render_inline(component)
        expect(page).to have_css('input[type="text"]')
      end
    end

    context 'with email type' do
      let(:options) { { type: :email } }

      it 'renders email field' do
        render_inline(component)
        expect(page).to have_css('input[type="email"]')
      end
    end

    context 'with password type' do
      let(:options) { { type: :password } }

      it 'renders password field' do
        render_inline(component)
        expect(page).to have_css('input[type="password"]')
      end
    end

    context 'with number type' do
      let(:options) { { type: :number } }

      it 'renders number field' do
        render_inline(component)
        expect(page).to have_css('input[type="number"]')
      end
    end

    context 'with tel type' do
      let(:options) { { type: :tel } }

      it 'renders telephone field' do
        render_inline(component)
        expect(page).to have_css('input[type="tel"]')
      end
    end

    context 'with date type' do
      let(:options) { { type: :date } }

      it 'renders date field' do
        render_inline(component)
        expect(page).to have_css('input[type="date"]')
      end
    end

    context 'with placeholder' do
      let(:options) { { placeholder: 'Enter your email' } }

      it 'renders with placeholder' do
        render_inline(component)
        expect(page).to have_css('input[placeholder="Enter your email"]')
      end
    end

    context 'with autocomplete' do
      let(:options) { { autocomplete: 'email' } }

      it 'renders with autocomplete attribute' do
        render_inline(component)
        expect(page).to have_css('input[autocomplete="email"]')
      end
    end

    context 'with custom label' do
      let(:options) { { label: 'Email Address' } }

      it 'renders custom label' do
        render_inline(component)
        expect(page).to have_text('Email Address')
      end
    end

    context 'with hint' do
      let(:options) { { hint: 'We will never share your email' } }

      it 'renders hint text' do
        render_inline(component)
        expect(page).to have_text('We will never share your email')
      end
    end

    context 'with errors' do
      before do
        form.object.errors.add(:email, 'is invalid')
      end

      it 'renders error message' do
        render_inline(component)
        expect(page).to have_text('is invalid')
      end

      it 'applies error styling' do
        render_inline(component)
        expect(page).to have_css('input.border-red-300')
      end
    end

    context 'when required' do
      let(:options) { { required: true } }

      it 'marks field as required' do
        render_inline(component)
        expect(page).to have_text('Email *')
        expect(page).to have_css('input[required]')
      end
    end
  end
end