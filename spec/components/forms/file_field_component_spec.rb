require 'rails_helper'

RSpec.describe Forms::FileFieldComponent, type: :component do
  let(:form) { setup_form_builder(avatar: nil) }
  let(:attribute) { :avatar }
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
    it 'renders file upload container' do
      render_inline(component)
      expect(page).to have_css('.file-upload-container')
    end

    it 'renders label' do
      render_inline(component)
      expect(page).to have_css('label', text: 'Avatar')
    end

    context 'with drag and drop enabled (default)' do
      it 'renders drag drop zone' do
        render_inline(component)
        expect(page).to have_css('[data-controller="file-upload"]')
        expect(page).to have_css('[data-file-upload-target="dropZone"]')
      end

      it 'renders upload icon and text' do
        render_inline(component)
        expect(page).to have_css('svg.h-12.w-12.text-gray-400')
        expect(page).to have_text('Click to upload')
        expect(page).to have_text('or drag and drop')
      end

      it 'renders hidden file input' do
        render_inline(component)
        expect(page).to have_css('input[type="file"].sr-only[data-file-upload-target="input"]')
      end
    end

    context 'with drag and drop disabled' do
      let(:options) { { drag_drop: false } }

      it 'renders standard file input' do
        render_inline(component)
        expect(page).to have_css('input[type="file"]')
        expect(page).not_to have_css('[data-controller="file-upload"]')
      end
    end

    context 'with preview enabled (default)' do
      it 'renders file list area' do
        render_inline(component)
        expect(page).to have_css('[data-file-upload-target="fileList"]')
        expect(page).to have_text('Selected files will appear here')
      end
    end

    context 'with preview disabled' do
      let(:options) { { preview: false } }

      it 'does not render file list area' do
        render_inline(component)
        expect(page).not_to have_css('[data-file-upload-target="fileList"]')
      end
    end

    context 'with progress enabled (default)' do
      it 'renders progress area' do
        render_inline(component)
        expect(page).to have_css('[data-file-upload-target="progressArea"].hidden')
        expect(page).to have_css('[data-file-upload-target="progressBar"]')
        expect(page).to have_text('Uploading...')
      end
    end

    context 'with progress disabled' do
      let(:options) { { progress: false } }

      it 'does not render progress area' do
        render_inline(component)
        expect(page).not_to have_css('[data-file-upload-target="progressArea"]')
      end
    end

    context 'with file acceptance restrictions' do
      let(:options) { { accept: 'image/*,.pdf' } }

      it 'sets accept attribute on file input' do
        render_inline(component)
        expect(page).to have_css('input[type="file"][accept="image/*,.pdf"]')
      end

      it 'shows accepted formats text' do
        render_inline(component)
        expect(page).to have_text('Accepted formats: IMAGE, PDF')
      end

      it 'includes accepted types in data attributes' do
        render_inline(component)
        expect(page).to have_css('[data-accepted-types="image/*,.pdf"]')
      end
    end

    context 'with multiple files' do
      let(:options) { { multiple: true } }

      it 'sets multiple attribute on file input' do
        render_inline(component)
        expect(page).to have_css('input[type="file"][multiple]')
      end
    end

    context 'with max file size' do
      let(:options) { { max_file_size: 5_242_880 } } # 5MB

      it 'shows max file size text' do
        render_inline(component)
        expect(page).to have_text('Maximum file size: 5.0 MB')
      end

      it 'includes max file size in data attributes' do
        render_inline(component)
        expect(page).to have_css('[data-max-file-size="5242880"]')
      end
    end

    context 'with max files limit' do
      let(:options) { { max_files: 3 } }

      it 'includes max files in data attributes' do
        render_inline(component)
        expect(page).to have_css('[data-max-files="3"]')
      end
    end

    it 'renders error area' do
      render_inline(component)
      expect(page).to have_css('[data-file-upload-target="errorArea"].hidden')
      expect(page).to have_css('[data-file-upload-target="errorList"]')
    end

    context 'with custom label' do
      let(:options) { { label: 'Profile Picture' } }

      it 'uses custom label' do
        render_inline(component)
        expect(page).to have_text('Profile Picture')
      end
    end

    context 'with hint' do
      let(:options) { { hint: 'Upload a profile picture (JPG or PNG)' } }

      it 'renders hint text' do
        render_inline(component)
        expect(page).to have_text('Upload a profile picture (JPG or PNG)')
      end
    end

    context 'with errors' do
      before do
        form.object.errors.add(:avatar, 'file is required')
      end

      it 'shows error message' do
        render_inline(component)
        expect(page).to have_text('file is required')
      end

      it 'applies error styling to drop zone' do
        render_inline(component)
        expect(page).to have_css('.border-red-300')
      end
    end

    context 'when required' do
      let(:options) { { required: true } }

      it 'marks field as required' do
        render_inline(component)
        expect(page).to have_text('Avatar *')
        expect(page).to have_css('input[type="file"][required]')
      end
    end
  end

  describe 'data attributes' do
    let(:options) do
      {
        accept: 'image/*',
        max_file_size: 1_048_576, # 1MB
        max_files: 5
      }
    end

    it 'includes all necessary data attributes' do
      render_inline(component)
      expect(page).to have_css('[data-controller="file-upload"]')
      expect(page).to have_css('[data-max-file-size="1048576"]')
      expect(page).to have_css('[data-max-files="5"]')
      expect(page).to have_css('[data-accepted-types="image/*"]')
    end
  end

  describe 'JavaScript actions' do
    it 'includes necessary actions for drag and drop' do
      render_inline(component)
      drop_zone = page.find('[data-file-upload-target="dropZone"]')
      actions = drop_zone['data-action']
      
      expect(actions).to include('click->file-upload#openFileDialog')
      expect(actions).to include('dragover->file-upload#handleDragOver')
      expect(actions).to include('dragleave->file-upload#handleDragLeave')
      expect(actions).to include('drop->file-upload#handleDrop')
    end

    it 'includes file select action' do
      render_inline(component)
      expect(page).to have_css('input[data-action*="change->file-upload#handleFileSelect"]')
    end
  end

  describe '#humanize_file_size' do
    it 'converts bytes to human readable format' do
      expect(component.send(:humanize_file_size, 0)).to eq '0 B'
      expect(component.send(:humanize_file_size, 1024)).to eq '1.0 KB'
      expect(component.send(:humanize_file_size, 1_048_576)).to eq '1.0 MB'
      expect(component.send(:humanize_file_size, 1_073_741_824)).to eq '1.0 GB'
    end
  end

  describe '#accepted_formats_text' do
    context 'with no accept filter' do
      it 'returns all files' do
        expect(component.send(:accepted_formats_text)).to eq 'All files'
      end
    end

    context 'with file extensions' do
      let(:options) { { accept: '.jpg,.png,.pdf' } }

      it 'formats extensions' do
        expect(component.send(:accepted_formats_text)).to eq 'JPG, PNG, PDF'
      end
    end

    context 'with MIME types' do
      let(:options) { { accept: 'image/*,application/pdf' } }

      it 'formats MIME types' do
        expect(component.send(:accepted_formats_text)).to eq 'IMAGE/, APPLICATION/PDF'
      end
    end
  end
end