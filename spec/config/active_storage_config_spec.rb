require 'rails_helper'

RSpec.describe 'Active Storage Configuration' do
  describe 'variant processor configuration' do
    it 'uses mini_magick as the variant processor' do
      expect(Rails.application.config.active_storage.variant_processor).to eq(:mini_magick)
    end
    
    it 'uses mini_magick as the preview image processor' do
      expect(Rails.application.config.active_storage.preview_image_processor).to eq(:mini_magick)
    end
  end
  
  describe 'analyzers configuration' do
    it 'includes ImageMagick analyzer' do
      expect(Rails.application.config.active_storage.analyzers).to include(
        ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick
      )
    end
    
    it 'includes video analyzer' do
      expect(Rails.application.config.active_storage.analyzers).to include(
        ActiveStorage::Analyzer::VideoAnalyzer
      )
    end
  end
  
  describe 'previewers configuration' do
    it 'includes Poppler PDF previewer' do
      expect(Rails.application.config.active_storage.previewers).to include(
        ActiveStorage::Previewer::PopplerPDFPreviewer
      )
    end
    
    it 'includes video previewer' do
      expect(Rails.application.config.active_storage.previewers).to include(
        ActiveStorage::Previewer::VideoPreviewer
      )
    end
  end
  
  describe 'variant definitions' do
    it 'defines standard thumbnail variants' do
      expect(ActiveStorageVariants::THUMBNAIL_VARIANTS).to be_present
      expect(ActiveStorageVariants::THUMBNAIL_VARIANTS).to include(
        :thumb, :medium, :large
      )
    end
    
    it 'defines thumb variant with correct dimensions' do
      thumb_config = ActiveStorageVariants::THUMBNAIL_VARIANTS[:thumb]
      expect(thumb_config[:resize_to_limit]).to eq([200, 200])
      expect(thumb_config[:format]).to eq(:jpg)
      expect(thumb_config[:quality]).to eq(85)
    end
    
    it 'defines medium variant with correct dimensions' do
      medium_config = ActiveStorageVariants::THUMBNAIL_VARIANTS[:medium]
      expect(medium_config[:resize_to_limit]).to eq([800, 600])
      expect(medium_config[:quality]).to eq(90)
    end
    
    it 'defines large variant with correct dimensions' do
      large_config = ActiveStorageVariants::THUMBNAIL_VARIANTS[:large]
      expect(large_config[:resize_to_limit]).to eq([1200, 900])
      expect(large_config[:quality]).to eq(95)
    end
    
    it 'defines special variants for different use cases' do
      expect(ActiveStorageVariants::SPECIAL_VARIANTS).to include(
        :grid_thumb, :preview_full, :mobile_thumb, :mobile_preview
      )
    end
  end
  
  describe 'Document helpers' do
    let(:document) { create(:document, :with_pdf_file) }
    
    context 'when Document has ActiveStorageDocumentHelpers' do
      it 'responds to thumbnail_url' do
        expect(document).to respond_to(:thumbnail_url)
      end
      
      it 'responds to preview_url' do
        expect(document).to respond_to(:preview_url)
      end
      
      it 'responds to icon_for_content_type' do
        expect(document).to respond_to(:icon_for_content_type)
      end
    end
    
    describe '#thumbnail_url' do
      context 'when thumbnail is attached' do
        before do
          document.thumbnail.attach(
            io: StringIO.new('fake thumbnail'),
            filename: 'thumb.jpg',
            content_type: 'image/jpeg'
          )
        end
        
        it 'returns the thumbnail blob path' do
          expect(document.thumbnail_url).to include('rails/active_storage/blobs')
        end
      end
      
      context 'when no thumbnail but file is an image' do
        let(:image_doc) { create(:image_document) }
        
        it 'returns a variant path' do
          url = image_doc.thumbnail_url
          expect(url).to be_present
        end
      end
      
      context 'when file is not previewable' do
        let(:doc) { create(:document, :with_pdf_file) }
        
        it 'returns icon for content type' do
          allow(doc.file).to receive(:variable?).and_return(false)
          allow(doc).to receive(:preview).and_return(double(attached?: false))
          
          expect(doc.thumbnail_url).to match(/pdf-icon.*\.svg/)
        end
      end
    end
    
    describe '#icon_for_content_type' do
      it 'returns pdf icon for PDF files' do
        allow(document).to receive(:file_content_type).and_return('application/pdf')
        expect(document.icon_for_content_type).to match(/pdf-icon.*\.svg/)
      end
      
      it 'returns word icon for Word documents' do
        allow(document).to receive(:file_content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        expect(document.icon_for_content_type).to match(/word-icon.*\.svg/)
      end
      
      it 'returns excel icon for Excel files' do
        allow(document).to receive(:file_content_type).and_return('application/vnd.ms-excel')
        expect(document.icon_for_content_type).to match(/excel-icon.*\.svg/)
      end
      
      it 'returns generic icon for unknown types' do
        allow(document).to receive(:file_content_type).and_return('application/unknown')
        expect(document.icon_for_content_type).to match(/generic-icon.*\.svg/)
      end
    end
    
    describe '#preview_url' do
      context 'when preview is attached and variable' do
        before do
          document.preview.attach(
            io: StringIO.new('fake preview'),
            filename: 'preview.jpg',
            content_type: 'image/jpeg'
          )
        end
        
        it 'returns a variant path' do
          allow(document.preview).to receive(:variable?).and_return(true)
          url = document.preview_url
          expect(url).to be_present
        end
      end
      
      context 'when file is previewable but no preview attached' do
        it 'returns blob path' do
          allow(document.file).to receive(:previewable?).and_return(true)
          url = document.preview_url
          expect(url).to include('rails/active_storage/blobs')
        end
      end
      
      context 'when file is not previewable' do
        it 'returns nil' do
          allow(document).to receive(:preview).and_return(double(attached?: false))
          allow(document.file).to receive(:previewable?).and_return(false)
          expect(document.preview_url).to be_nil
        end
      end
    end
  end
end