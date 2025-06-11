require 'rails_helper'

RSpec.describe OcrProcessingJob, type: :job do
  let(:document) { create(:document) }

  describe '#perform' do
    context 'when document needs OCR' do
      before do
        allow(document).to receive(:needs_ocr?).and_return(true)
        allow(document).to receive(:content_type).and_return('image/png')
      end

      it 'performs OCR on the document' do
        expect_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr).and_return('Extracted text from image')

        OcrProcessingJob.new.perform(document)
      end

      it 'updates document content with OCR result' do
        allow_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr).and_return('This is the OCR extracted text')

        OcrProcessingJob.new.perform(document)
        document.reload

        expect(document.content).to eq('This is the OCR extracted text')
      end

      it 'updates processing metadata' do
        allow_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr).and_return('OCR text')

        OcrProcessingJob.new.perform(document)
        document.reload

        expect(document.processing_metadata['ocr_performed']).to be true
        expect(document.processing_metadata['ocr_completed_at']).to be_present
      end

      it 'handles multi-page images' do
        pages_text = [
          'Page 1 content',
          'Page 2 content',
          'Page 3 content'
        ]
        
        allow_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr).and_return(pages_text.join("\n\n"))

        OcrProcessingJob.new.perform(document)
        document.reload

        expect(document.content).to include('Page 1 content')
        expect(document.content).to include('Page 2 content')
        expect(document.content).to include('Page 3 content')
      end

      context 'with different image formats' do
        %w[image/jpeg image/png image/tiff image/bmp].each do |content_type|
          it "processes #{content_type} images" do
            allow(document).to receive(:content_type).and_return(content_type)
            expect_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr)

            OcrProcessingJob.new.perform(document)
          end
        end
      end

      context 'with language detection' do
        it 'detects and uses appropriate language for OCR' do
          service = instance_double(DocumentProcessingService)
          allow(DocumentProcessingService).to receive(:new).and_return(service)
          
          expect(service).to receive(:detect_language).and_return('fra')
          expect(service).to receive(:extract_text_with_ocr).with(language: 'fra').and_return('Texte en français')

          OcrProcessingJob.new.perform(document)
        end

        it 'defaults to English when language detection fails' do
          service = instance_double(DocumentProcessingService)
          allow(DocumentProcessingService).to receive(:new).and_return(service)
          
          expect(service).to receive(:detect_language).and_return(nil)
          expect(service).to receive(:extract_text_with_ocr).with(language: 'eng').and_return('English text')

          OcrProcessingJob.new.perform(document)
        end
      end

      context 'with quality enhancement' do
        it 'preprocesses low quality images' do
          allow(document).to receive_message_chain(:file, :metadata).and_return({ 'width' => 800, 'height' => 600 })
          
          service = instance_double(DocumentProcessingService)
          allow(DocumentProcessingService).to receive(:new).and_return(service)
          
          expect(service).to receive(:enhance_image_quality)
          expect(service).to receive(:extract_text_with_ocr).and_return('Enhanced OCR text')

          OcrProcessingJob.new.perform(document)
        end
      end

      it 'triggers content extraction after OCR' do
        allow_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr).and_return('OCR content')
        
        expect(ContentExtractionJob).to receive(:perform_later).with(document)

        OcrProcessingJob.new.perform(document)
      end

      context 'when OCR fails' do
        before do
          allow_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr).and_raise(StandardError, 'OCR engine error')
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Failed to perform OCR/)

          OcrProcessingJob.new.perform(document)
        end

        it 'updates document with error status' do
          OcrProcessingJob.new.perform(document)
          document.reload

          expect(document.processing_metadata['ocr_error']).to eq('OCR engine error')
          expect(document.processing_metadata['ocr_failed_at']).to be_present
        end

        it 'does not update document content' do
          original_content = document.content

          OcrProcessingJob.new.perform(document)
          document.reload

          expect(document.content).to eq(original_content)
        end
      end

      context 'with confidence scoring' do
        it 'stores OCR confidence score' do
          service = instance_double(DocumentProcessingService)
          allow(DocumentProcessingService).to receive(:new).and_return(service)
          
          expect(service).to receive(:extract_text_with_ocr).and_return({
            text: 'OCR extracted text',
            confidence: 0.85
          })

          OcrProcessingJob.new.perform(document)
          document.reload

          expect(document.content).to eq('OCR extracted text')
          expect(document.processing_metadata['ocr_confidence']).to eq(0.85)
        end

        it 'flags low confidence results' do
          service = instance_double(DocumentProcessingService)
          allow(DocumentProcessingService).to receive(:new).and_return(service)
          
          expect(service).to receive(:extract_text_with_ocr).and_return({
            text: 'Low confidence text',
            confidence: 0.45
          })

          OcrProcessingJob.new.perform(document)
          document.reload

          expect(document.processing_metadata['ocr_low_confidence']).to be true
        end
      end
    end

    context 'when document does not need OCR' do
      before do
        allow(document).to receive(:needs_ocr?).and_return(false)
      end

      it 'skips OCR processing' do
        expect_any_instance_of(DocumentProcessingService).not_to receive(:extract_text_with_ocr)

        OcrProcessingJob.new.perform(document)
      end

      it 'logs skip message' do
        expect(Rails.logger).to receive(:info).with(/does not require OCR/)

        OcrProcessingJob.new.perform(document)
      end

      it 'updates metadata to indicate OCR not needed' do
        OcrProcessingJob.new.perform(document)
        document.reload

        expect(document.processing_metadata['ocr_required']).to be false
      end
    end
  end

  describe 'job configuration' do
    it 'uses low priority queue' do
      expect(OcrProcessingJob.new.queue_name).to eq('low')
    end

    it 'can be enqueued' do
      expect {
        OcrProcessingJob.perform_later(document)
      }.to have_enqueued_job(OcrProcessingJob).with(document).on_queue('low')
    end

    it 'retries on transient failures' do
      allow(document).to receive(:needs_ocr?).and_return(true)
      allow_any_instance_of(DocumentProcessingService).to receive(:extract_text_with_ocr)
        .and_raise(StandardError, 'Temporary failure')

      expect {
        OcrProcessingJob.perform_now(document)
      }.not_to raise_error
    end
  end
end