require 'rails_helper'

RSpec.describe DocumentProcessingJob, type: :job do
  describe '#perform' do
    let(:document) { create(:document) }
    
    before do
      # Mock other jobs to prevent actual execution
      allow(VirusScanJob).to receive(:perform_now)
      allow(ContentExtractionJob).to receive(:perform_now)
      allow(PreviewGenerationJob).to receive(:perform_later)
      allow(ThumbnailGenerationJob).to receive(:perform_later)
      allow(MetadataExtractionJob).to receive(:perform_later)
      allow(AutoTaggingJob).to receive(:perform_later)
      allow(OcrProcessingJob).to receive(:perform_later)
      allow(document).to receive(:reindex)
    end
    
    it 'marks document as processing' do
      expect(document).to receive(:start_processing!)
      described_class.perform_now(document)
    end
    
    it 'runs virus scan first' do
      expect(VirusScanJob).to receive(:perform_now).with(document)
      described_class.perform_now(document)
    end
    
    it 'runs content extraction' do
      expect(ContentExtractionJob).to receive(:perform_now).with(document)
      described_class.perform_now(document)
    end
    
    it 'queues preview and thumbnail generation' do
      expect(PreviewGenerationJob).to receive(:perform_later).with(document)
      expect(ThumbnailGenerationJob).to receive(:perform_later).with(document)
      described_class.perform_now(document)
    end
    
    it 'queues metadata extraction and auto-tagging' do
      expect(MetadataExtractionJob).to receive(:perform_later).with(document)
      expect(AutoTaggingJob).to receive(:perform_later).with(document)
      described_class.perform_now(document)
    end
    
    context 'when document needs OCR' do
      before do
        allow(document).to receive(:needs_ocr?).and_return(true)
      end
      
      it 'queues OCR processing' do
        expect(OcrProcessingJob).to receive(:perform_later).with(document)
        described_class.perform_now(document)
      end
      
      it 'does not mark as completed immediately' do
        expect(document).not_to receive(:complete_processing!)
        described_class.perform_now(document)
      end
    end
    
    context 'when document does not need OCR' do
      before do
        allow(document).to receive(:needs_ocr?).and_return(false)
      end
      
      it 'marks as completed' do
        expect(document).to receive(:complete_processing!)
        described_class.perform_now(document)
      end
    end
    
    context 'when virus is detected' do
      before do
        allow(document).to receive(:virus_scan_infected?).and_return(true)
      end
      
      it 'stops processing after virus scan' do
        expect(ContentExtractionJob).not_to receive(:perform_now)
        described_class.perform_now(document)
      end
    end
    
    context 'when processing fails' do
      before do
        allow(ContentExtractionJob).to receive(:perform_now).and_raise(StandardError, 'Test error')
      end
      
      it 'marks document as failed' do
        expect(document).to receive(:fail_processing!).with('Test error')
        expect { described_class.perform_now(document) }.to raise_error(StandardError)
      end
    end
    
    it 'reindexes document for search' do
      expect(document).to receive(:reindex)
      described_class.perform_now(document)
    end
    
    context 'when document is already processing' do
      before do
        document.update!(processing_status: 'processing')
      end
      
      it 'does not process again' do
        expect(document).not_to receive(:start_processing!)
        described_class.perform_now(document)
      end
    end
  end
end