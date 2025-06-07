require 'rails_helper'

RSpec.describe ContentExtractionJob, type: :job do
  describe '#perform' do
    let(:document) { create(:document) }
    
    context 'with PDF file' do
      before do
        allow(document).to receive(:pdf?).and_return(true)
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:open).and_yield(StringIO.new('PDF content'))
        
        # Mock PDF::Reader
        pdf_reader = double('PDF::Reader')
        allow(PDF::Reader).to receive(:new).and_return(pdf_reader)
        allow(pdf_reader).to receive(:pages).and_return([
          double(text: 'Page 1 content'),
          double(text: 'Page 2 content')
        ])
      end
      
      it 'extracts text from PDF' do
        expect(document).to receive(:update!).with(content: "Page 1 content\nPage 2 content")
        described_class.perform_now(document)
      end
      
      it 'adds metadata for word count' do
        described_class.perform_now(document)
        expect(document.metadata.where(key: 'word_count')).to exist
      end
      
      it 'adds extraction method metadata' do
        described_class.perform_now(document)
        expect(document.metadata.where(key: 'extraction_method', value: 'pdf-reader')).to exist
      end
    end
    
    context 'with Office document' do
      let(:job) { described_class.new }
      
      before do
        allow(document).to receive(:office_document?).and_return(true)
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document).to receive(:pdf?).and_return(false)
        allow(document.file).to receive(:content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        
        # Mock the extract_office_content method directly
        allow(job).to receive(:extract_office_content).with(document).and_return('Office document content')
        
        # Mock the metadata creation
        allow(document).to receive(:add_metadata)
      end
      
      it 'extracts text using LibreOffice' do
        expect(document).to receive(:update!).with(content: 'Office document content')
        expect(document).to receive(:add_metadata).with('word_count', 3)
        expect(document).to receive(:add_metadata).with('extraction_method', 'libreoffice')
        job.perform(document)
      end
    end
    
    context 'with text file' do
      before do
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:content_type).and_return('text/plain')
        allow(document.file).to receive(:download).and_return('Plain text content')
      end
      
      it 'extracts text directly' do
        expect(document).to receive(:update!).with(content: 'Plain text content')
        described_class.perform_now(document)
      end
    end
    
    context 'with unsupported file type' do
      before do
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document).to receive(:pdf?).and_return(false)
        allow(document).to receive(:office_document?).and_return(false)
        allow(document.file).to receive(:content_type).and_return('application/octet-stream')
      end
      
      it 'does not update content' do
        expect(document).not_to receive(:update!)
        described_class.perform_now(document)
      end
    end
    
    context 'when extraction fails' do
      before do
        allow(document).to receive(:pdf?).and_return(true)
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:open).and_raise(StandardError, 'Read error')
      end
      
      it 'handles errors gracefully' do
        expect { described_class.perform_now(document) }.not_to raise_error
      end
      
      it 'does not update content' do
        expect(document).not_to receive(:update!)
        described_class.perform_now(document)
      end
    end
  end
end