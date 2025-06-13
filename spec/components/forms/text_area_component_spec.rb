require 'rails_helper'

RSpec.describe Forms::TextAreaComponent, type: :component do
  let(:form) { setup_form_builder(description: 'Sample text') }
  let(:attribute) { :description }
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
    it 'renders textarea element' do
      render_inline(component)
      expect(page).to have_css('textarea')
    end

    it 'renders label' do
      render_inline(component)
      expect(page).to have_css('label', text: 'Description')
    end

    it 'displays current value' do
      render_inline(component)
      expect(page).to have_css('textarea', text: 'Sample text')
    end

    context 'with default rows' do
      it 'renders with 3 rows' do
        render_inline(component)
        expect(page).to have_css('textarea[rows="3"]')
      end
    end

    context 'with custom rows' do
      let(:options) { { rows: 5 } }

      it 'renders with specified rows' do
        render_inline(component)
        expect(page).to have_css('textarea[rows="5"]')
      end
    end

    context 'with placeholder' do
      let(:options) { { placeholder: 'Enter your description here...' } }

      it 'renders with placeholder' do
        render_inline(component)
        expect(page).to have_css('textarea[placeholder="Enter your description here..."]')
      end
    end

    context 'with resize disabled' do
      let(:options) { { resize: false } }

      it 'applies resize-none class' do
        render_inline(component)
        expect(page).to have_css('textarea.resize-none')
      end
    end

    context 'with resize enabled (default)' do
      it 'does not apply resize-none class' do
        render_inline(component)
        expect(page).not_to have_css('textarea.resize-none')
      end
    end

    context 'with custom label' do
      let(:options) { { label: 'Detailed Description' } }

      it 'uses custom label' do
        render_inline(component)
        expect(page).to have_text('Detailed Description')
      end
    end

    context 'with hint' do
      let(:options) { { hint: 'Provide a detailed description (minimum 50 characters)' } }

      it 'renders hint text' do
        render_inline(component)
        expect(page).to have_text('Provide a detailed description (minimum 50 characters)')
      end
    end

    context 'with errors' do
      before do
        form.object.errors.add(:description, 'is too short')
      end

      it 'shows error message' do
        render_inline(component)
        expect(page).to have_text('is too short')
      end

      it 'applies error styling' do
        render_inline(component)
        expect(page).to have_css('textarea.border-red-300')
      end
    end

    context 'when required' do
      let(:options) { { required: true } }

      it 'marks field as required' do
        render_inline(component)
        expect(page).to have_text('Description *')
        expect(page).to have_css('textarea[required]')
      end
    end

    context 'with custom class' do
      let(:options) { { class: 'custom-textarea' } }

      it 'includes custom class' do
        render_inline(component)
        expect(page).to have_css('textarea.custom-textarea')
      end
    end

    context 'with auto-resize enabled' do
      let(:options) { { auto_resize: true } }

      it 'adds auto-resize controller' do
        render_inline(component)
        expect(page).to have_css('textarea[data-controller*="auto-resize"]')
        expect(page).to have_css('textarea[data-action*="input->auto-resize#resize"]')
      end

      it 'disables manual resize' do
        render_inline(component)
        expect(page).to have_css('textarea.resize-none')
      end
    end

    context 'with character count enabled' do
      let(:options) { { character_count: true } }

      it 'adds character count controller' do
        render_inline(component)
        expect(page).to have_css('textarea[data-controller*="character-count"]')
        expect(page).to have_css('textarea[data-action*="input->character-count#update"]')
      end

      it 'renders character count display' do
        render_inline(component)
        expect(page).to have_text('11 characters')
      end

      it 'adds padding for character count' do
        render_inline(component)
        expect(page).to have_css('textarea.pb-8')
      end
    end

    context 'with max length' do
      let(:options) { { character_count: true, max_length: 100 } }

      it 'sets maxlength attribute' do
        render_inline(component)
        expect(page).to have_css('textarea[maxlength="100"]')
      end

      it 'shows character count with limit' do
        render_inline(component)
        expect(page).to have_text('11/100')
      end
    end

    context 'with both auto-resize and character count' do
      let(:options) { { auto_resize: true, character_count: true } }

      it 'adds both controllers' do
        render_inline(component)
        expect(page).to have_css('textarea[data-controller*="auto-resize"]')
        expect(page).to have_css('textarea[data-controller*="character-count"]')
      end
    end
  end

  describe 'styling' do
    it 'applies Tailwind textarea styles' do
      render_inline(component)
      expect(page).to have_css('textarea.block.w-full.rounded-md.shadow-sm')
      expect(page).to have_css('textarea.border-gray-300')
      expect(page).to have_css('textarea.focus\\:border-indigo-500')
      expect(page).to have_css('textarea.focus\\:ring-indigo-500')
    end
  end

  describe '#text_area_classes' do
    it 'includes field classes' do
      classes = component.send(:text_area_classes)
      expect(classes).to include('block w-full')
    end

    context 'with resize disabled' do
      let(:options) { { resize: false } }

      it 'includes resize-none' do
        classes = component.send(:text_area_classes)
        expect(classes).to include('resize-none')
      end
    end
  end
end