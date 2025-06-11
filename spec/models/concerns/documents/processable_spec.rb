require 'rails_helper'

RSpec.describe Documents::Processable do
  let(:document) { create(:document) }

  describe 'processing status' do
    it 'has default processing status of pending' do
      expect(document.processing_status).to eq('pending')
    end

    describe '#mark_processing_started!' do
      it 'updates processing status to processing' do
        document.mark_processing_started!
        expect(document.processing_status).to eq('processing')
        expect(document.processing_started_at).to be_present
      end
    end

    describe '#mark_processing_completed!' do
      it 'updates processing status to completed' do
        document.mark_processing_completed!
        expect(document.processing_status).to eq('completed')
        expect(document.processing_completed_at).to be_present
      end

      it 'stores processing metadata' do
        metadata = { pages: 10, word_count: 500 }
        document.mark_processing_completed!(metadata: metadata)
        expect(document.processing_metadata).to include(metadata.stringify_keys)
      end
    end

    describe '#mark_processing_failed!' do
      it 'updates processing status to failed' do
        error = 'Invalid file format'
        document.mark_processing_failed!(error)
        expect(document.processing_status).to eq('failed')
        expect(document.processing_error).to eq(error)
      end
    end

    describe '#processing_in_progress?' do
      it 'returns true when processing' do
        document.processing_status = 'processing'
        expect(document.processing_in_progress?).to be true
      end

      it 'returns false when not processing' do
        document.processing_status = 'completed'
        expect(document.processing_in_progress?).to be false
      end
    end

    describe '#processing_completed?' do
      it 'returns true when completed' do
        document.processing_status = 'completed'
        expect(document.processing_completed?).to be true
      end

      it 'returns false when not completed' do
        document.processing_status = 'processing'
        expect(document.processing_completed?).to be false
      end
    end

    describe '#processing_failed?' do
      it 'returns true when failed' do
        document.processing_status = 'failed'
        expect(document.processing_failed?).to be true
      end

      it 'returns false when not failed' do
        document.processing_status = 'completed'
        expect(document.processing_failed?).to be false
      end
    end

    describe '#retry_processing!' do
      before do
        document.mark_processing_failed!('Network error')
      end

      it 'resets processing status to pending' do
        document.retry_processing!
        expect(document.processing_status).to eq('pending')
        expect(document.processing_error).to be_nil
        expect(document.processing_started_at).to be_nil
        expect(document.processing_completed_at).to be_nil
      end

      it 'triggers processing job' do
        expect(DocumentProcessingJob).to receive(:perform_later).with(document)
        document.retry_processing!
      end
    end

    describe '#processing_duration' do
      it 'returns nil when not started' do
        expect(document.processing_duration).to be_nil
      end

      it 'calculates duration when completed' do
        document.processing_started_at = 2.minutes.ago
        document.processing_completed_at = Time.current
        expect(document.processing_duration).to be_within(1).of(120)
      end

      it 'calculates ongoing duration when in progress' do
        document.processing_started_at = 1.minute.ago
        document.processing_status = 'processing'
        expect(document.processing_duration).to be_within(1).of(60)
      end
    end
  end

  describe 'content extraction' do
    describe '#extract_text_content' do
      context 'with PDF file' do
        before do
          allow(document).to receive(:content_type).and_return('application/pdf')
          allow(document.file).to receive(:attached?).and_return(true)
        end

        it 'extracts text from PDF' do
          expect(document).to receive(:extract_pdf_text)
          document.extract_text_content
        end
      end

      context 'with Word document' do
        before do
          allow(document).to receive(:content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
          allow(document.file).to receive(:attached?).and_return(true)
        end

        it 'extracts text from Word document' do
          expect(document).to receive(:extract_docx_text)
          document.extract_text_content
        end
      end

      context 'with text file' do
        before do
          allow(document).to receive(:content_type).and_return('text/plain')
          allow(document.file).to receive(:attached?).and_return(true)
        end

        it 'extracts text directly' do
          expect(document).to receive(:extract_plain_text)
          document.extract_text_content
        end
      end
    end

    describe '#needs_ocr?' do
      it 'returns true for image files' do
        allow(document).to receive(:content_type).and_return('image/png')
        expect(document.needs_ocr?).to be true
      end

      it 'returns false for text files' do
        allow(document).to receive(:content_type).and_return('text/plain')
        expect(document.needs_ocr?).to be false
      end
    end

    describe '#extract_metadata' do
      it 'extracts basic file metadata' do
        allow(document.file).to receive_message_chain(:blob, :metadata).and_return({
          'identified' => true,
          'width' => 1920,
          'height' => 1080
        })
        
        metadata = document.extract_metadata
        expect(metadata).to include(
          file_size: document.file_size,
          content_type: document.content_type,
          file_name: document.file_name
        )
      end
    end
  end

  describe 'scopes' do
    let!(:pending_doc) { create(:document, processing_status: 'pending') }
    let!(:processing_doc) { create(:document, processing_status: 'processing') }
    let!(:completed_doc) { create(:document, processing_status: 'completed') }
    let!(:failed_doc) { create(:document, processing_status: 'failed') }

    describe '.pending_processing' do
      it 'returns documents pending processing' do
        expect(Document.pending_processing).to include(pending_doc)
        expect(Document.pending_processing).not_to include(processing_doc, completed_doc, failed_doc)
      end
    end

    describe '.processing' do
      it 'returns documents currently processing' do
        expect(Document.processing).to include(processing_doc)
        expect(Document.processing).not_to include(pending_doc, completed_doc, failed_doc)
      end
    end

    describe '.processed' do
      it 'returns successfully processed documents' do
        expect(Document.processed).to include(completed_doc)
        expect(Document.processed).not_to include(pending_doc, processing_doc, failed_doc)
      end
    end

    describe '.failed_processing' do
      it 'returns documents that failed processing' do
        expect(Document.failed_processing).to include(failed_doc)
        expect(Document.failed_processing).not_to include(pending_doc, processing_doc, completed_doc)
      end
    end
  end
end