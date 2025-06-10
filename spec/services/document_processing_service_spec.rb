require 'rails_helper'

RSpec.describe DocumentProcessingService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, uploaded_by: user, space: space) }
  let(:service) { described_class.new(document) }

  describe '#process!' do
    it 'processes document through all stages' do
      expect(service).to receive(:extract_text)
      expect(service).to receive(:extract_metadata)
      expect(service).to receive(:generate_thumbnail)
      expect(service).to receive(:run_virus_scan)
      expect(service).to receive(:apply_auto_tagging)
      
      service.process!
    end

    it 'updates document processing status' do
      allow(service).to receive(:extract_text).and_return(true)
      allow(service).to receive(:extract_metadata).and_return(true)
      allow(service).to receive(:generate_thumbnail).and_return(true)
      allow(service).to receive(:run_virus_scan).and_return(true)
      allow(service).to receive(:apply_auto_tagging).and_return(true)
      
      service.process!
      
      expect(document.reload.processing_status).to eq('completed')
    end

    it 'handles processing errors' do
      allow(service).to receive(:extract_text).and_raise(StandardError, 'Processing failed')
      
      expect { service.process! }.not_to raise_error
      expect(document.reload.processing_status).to eq('failed')
    end
  end

  describe '#extract_text' do
    context 'with PDF file' do
      before do
        allow(document).to receive(:file_content_type).and_return('application/pdf')
        allow(document.file).to receive(:download).and_return('PDF content')
      end

      it 'extracts text from PDF' do
        allow(service).to receive(:extract_pdf_text).and_return('Extracted PDF text')
        
        service.send(:extract_text)
        
        expect(document.extracted_text).to eq('Extracted PDF text')
      end
    end

    context 'with image file' do
      before do
        allow(document).to receive(:file_content_type).and_return('image/jpeg')
      end

      it 'uses OCR for text extraction' do
        allow(service).to receive(:extract_ocr_text).and_return('OCR extracted text')
        
        service.send(:extract_text)
        
        expect(document.extracted_text).to eq('OCR extracted text')
      end
    end

    context 'with Word document' do
      before do
        allow(document).to receive(:file_content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      end

      it 'extracts text from Word document' do
        allow(service).to receive(:extract_docx_text).and_return('Word document text')
        
        service.send(:extract_text)
        
        expect(document.extracted_text).to eq('Word document text')
      end
    end
  end

  describe '#extract_metadata' do
    it 'extracts file metadata' do
      allow(document.file).to receive(:byte_size).and_return(1024)
      allow(document.file).to receive(:filename).and_return('test.pdf')
      
      service.send(:extract_metadata)
      
      expect(document.file_size).to eq(1024)
    end

    it 'calculates content hash' do
      allow(document.file).to receive(:download).and_return('file content')
      
      service.send(:extract_metadata)
      
      expect(document.content_hash).not_to be_nil
    end
  end

  describe '#generate_thumbnail' do
    context 'with image file' do
      before do
        allow(document).to receive(:file_content_type).and_return('image/jpeg')
      end

      it 'generates thumbnail for image' do
        expect(service).to receive(:generate_image_thumbnail)
        
        service.send(:generate_thumbnail)
      end
    end

    context 'with PDF file' do
      before do
        allow(document).to receive(:file_content_type).and_return('application/pdf')
      end

      it 'generates thumbnail for PDF' do
        expect(service).to receive(:generate_pdf_thumbnail)
        
        service.send(:generate_thumbnail)
      end
    end
  end

  describe '#run_virus_scan' do
    it 'scans document for viruses' do
      allow(service).to receive(:scan_with_clamav).and_return({ clean: true, signature: nil })
      
      service.send(:run_virus_scan)
      
      expect(document.virus_scan_status).to eq('clean')
    end

    it 'quarantines infected files' do
      allow(service).to receive(:scan_with_clamav).and_return({ clean: false, signature: 'Trojan.Generic' })
      
      service.send(:run_virus_scan)
      
      expect(document.virus_scan_status).to eq('infected')
      expect(document.quarantined?).to be true
    end
  end

  describe '#apply_auto_tagging' do
    before do
      document.update(extracted_text: 'contract agreement legal document')
    end

    it 'applies automatic tags based on content' do
      service.send(:apply_auto_tagging)
      
      expect(document.tags.pluck(:name)).to include('contract', 'legal')
    end

    it 'does not duplicate existing tags' do
      document.tags.create!(name: 'contract', organization: organization)
      
      service.send(:apply_auto_tagging)
      
      expect(document.tags.where(name: 'contract').count).to eq(1)
    end
  end

  describe 'private helper methods' do
    describe '#extract_pdf_text' do
      it 'extracts text from PDF using PDF reader' do
        pdf_content = 'Mock PDF content'
        allow(service).to receive(:read_pdf_content).and_return('Extracted text from PDF')
        
        result = service.send(:extract_pdf_text, pdf_content)
        
        expect(result).to eq('Extracted text from PDF')
      end
    end

    describe '#extract_ocr_text' do
      it 'uses Tesseract for OCR' do
        image_content = 'Mock image content'
        allow(service).to receive(:tesseract_ocr).and_return('OCR result text')
        
        result = service.send(:extract_ocr_text, image_content)
        
        expect(result).to eq('OCR result text')
      end
    end

    describe '#calculate_content_hash' do
      it 'generates SHA256 hash of content' do
        content = 'test content'
        hash = service.send(:calculate_content_hash, content)
        
        expect(hash).to eq(Digest::SHA256.hexdigest(content))
      end
    end

    describe '#suggest_tags_from_content' do
      it 'suggests tags based on content keywords' do
        content = 'construction contract building architecture permit'
        tags = service.send(:suggest_tags_from_content, content)
        
        expect(tags).to include('construction', 'contract', 'architecture')
      end

      it 'filters out common words' do
        content = 'the contract and agreement with building'
        tags = service.send(:suggest_tags_from_content, content)
        
        expect(tags).not_to include('the', 'and', 'with')
      end
    end

    describe '#needs_ocr?' do
      it 'returns true for image files' do
        allow(document).to receive(:file_content_type).and_return('image/jpeg')
        expect(service.send(:needs_ocr?)).to be true
      end

      it 'returns false for text-based files' do
        allow(document).to receive(:file_content_type).and_return('application/pdf')
        expect(service.send(:needs_ocr?)).to be false
      end
    end
  end
end