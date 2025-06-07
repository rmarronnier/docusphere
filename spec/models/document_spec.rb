require 'rails_helper'

RSpec.describe Document, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:space) }
    it { should belong_to(:folder).optional }
    it { should belong_to(:parent).optional }
    it { should have_many(:children).dependent(:destroy) }
    it { should have_many(:shares).dependent(:destroy) }
    it { should have_many(:shared_users).through(:shares) }
    it { should have_many(:document_versions).dependent(:destroy) }
    it { should have_many(:metadata).dependent(:destroy) }
    it { should have_many(:document_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:document_tags) }
    it { should have_many(:workflow_submissions).dependent(:destroy) }
    it { should have_many(:workflows).through(:workflow_submissions) }
    it { should have_many(:links).dependent(:destroy) }
    it { should have_many(:linked_documents).through(:links) }
  end

  describe 'validations' do
    subject { build(:document) }
    
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:file) }
    
    context 'file size validation' do
      let(:document) { build(:document) }
      
      it 'rejects files larger than 100MB' do
        allow(document).to receive(:file_attached?).and_return(true)
        allow(document).to receive(:file_size).and_return(101.megabytes)
        document.valid?
        expect(document.errors[:file_size]).to include('doit être inférieur ou égal à 104857600')
      end
      
      it 'accepts files up to 100MB' do
        allow(document).to receive(:file_attached?).and_return(true)
        allow(document).to receive(:file_size).and_return(100.megabytes)
        expect(document).to be_valid
      end
    end
  end

  describe 'state machine' do
    let(:document) { create(:document) }

    it 'starts in draft state' do
      expect(document.status).to eq('draft')
      expect(document).to be_draft
    end

    describe 'transitions' do
      it 'can transition from draft to published' do
        expect { document.publish! }.to change { document.status }.from('draft').to('published')
      end

      it 'can transition from published to locked' do
        document.publish!
        expect { document.lock! }.to change { document.status }.from('published').to('locked')
      end

      it 'can transition from locked to archived' do
        document.publish!
        document.lock!
        expect { document.archive! }.to change { document.status }.from('locked').to('archived')
      end
    end
  end

  describe 'file format detection' do
    describe '#document_type' do
      context 'with PDF file' do
        let(:document) { create(:pdf_document) }
        
        it 'returns pdf type' do
          expect(document.document_type).to eq('pdf')
        end
      end

      context 'with Word file' do
        let(:document) { create(:word_document) }
        
        it 'returns word type' do
          expect(document.document_type).to eq('word')
        end
      end

      context 'with image file' do
        let(:document) { create(:image_document) }
        
        it 'returns image type' do
          expect(document.document_type).to eq('image')
        end
      end

      context 'with unsupported file' do
        let(:document) { build(:document) }
        
        before do
          document.file.attach(
            io: StringIO.new("Unknown content"),
            filename: "test.unknown",
            content_type: "application/unknown"
          )
        end
        
        it 'returns other type' do
          expect(document.document_type).to eq('other')
        end
      end
    end

    describe '#supported_format?' do
      let(:pdf_document) { create(:pdf_document) }
      let(:unsupported_document) { build(:document) }
      
      before do
        unsupported_document.file.attach(
          io: StringIO.new("Unknown content"),
          filename: "test.unknown",
          content_type: "application/unknown"
        )
      end
      
      it 'returns true for supported formats' do
        expect(pdf_document.supported_format?).to be true
      end
      
      it 'returns false for unsupported formats' do
        expect(unsupported_document.supported_format?).to be false
      end
    end
  end

  describe 'search data' do
    let(:document) { create(:document, :with_tags) }
    
    describe '#search_data' do
      it 'includes all searchable fields' do
        search_data = document.search_data
        
        expect(search_data).to include(
          :title,
          :description,
          :content,
          :metadata_text,
          :document_type,
          :created_at,
          :user_id,
          :space_id,
          :tags
        )
      end
      
      it 'includes tag names' do
        search_data = document.search_data
        expect(search_data[:tags]).to eq(document.tags.pluck(:name))
      end
    end
  end

  describe 'traits' do
    describe 'status traits' do
      it 'creates published documents' do
        document = create(:document, :published)
        expect(document).to be_published
      end
      
      it 'creates locked documents' do
        document = create(:document, :locked)
        expect(document).to be_locked
      end
      
      it 'creates archived documents' do
        document = create(:document, :archived)
        expect(document).to be_archived
      end
    end

    describe 'with_tags trait' do
      let(:document) { create(:document, :with_tags) }
      
      it 'creates a document with tags' do
        expect(document.tags.count).to eq(3)
      end
    end

    describe 'with_versions trait' do
      let(:document) { create(:document, :with_versions) }
      
      it 'creates a document with versions' do
        expect(document.document_versions.count).to eq(2)
      end
    end
  end
  
  describe 'processing' do
    let(:document) { create(:document) }
    
    describe 'processing status' do
      it 'starts with pending status' do
        expect(document.processing_status).to eq('pending')
        expect(document).to be_pending
      end
      
      it 'can mark processing as started' do
        document.start_processing!
        expect(document).to be_processing
        expect(document.processing_started_at).to be_present
      end
      
      it 'can mark processing as completed' do
        document.start_processing!
        document.complete_processing!
        expect(document).to be_completed
        expect(document.processing_completed_at).to be_present
        expect(document.processing_error).to be_nil
      end
      
      it 'can mark processing as failed' do
        document.fail_processing!('Test error')
        expect(document).to be_failed
        expect(document.processing_error).to eq('Test error')
        expect(document.processing_completed_at).to be_present
      end
    end
    
    describe 'file type detection' do
      it 'detects PDF files' do
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:content_type).and_return('application/pdf')
        expect(document).to be_pdf
        expect(document).not_to be_image
        expect(document).not_to be_office_document
      end
      
      it 'detects image files' do
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:content_type).and_return('image/jpeg')
        expect(document).to be_image
        expect(document).not_to be_pdf
        expect(document).not_to be_office_document
      end
      
      it 'detects office documents' do
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        expect(document).to be_office_document
        expect(document).not_to be_pdf
        expect(document).not_to be_image
      end
    end
    
    describe 'preview generation' do
      it 'reports preview not generated initially' do
        expect(document).not_to be_preview_generated
      end
      
      it 'reports preview generated when attached' do
        document.preview.attach(
          io: StringIO.new('preview'),
          filename: 'preview.jpg',
          content_type: 'image/jpeg'
        )
        expect(document).to be_preview_generated
      end
    end
    
    describe 'OCR detection' do
      it 'needs OCR for images' do
        allow(document).to receive(:image?).and_return(true)
        expect(document).to be_needs_ocr
      end
      
      it 'needs OCR for PDFs without text' do
        allow(document).to receive(:pdf?).and_return(true)
        allow(document).to receive(:has_text?).and_return(false)
        expect(document).to be_needs_ocr
      end
      
      it 'does not need OCR for PDFs with text' do
        allow(document).to receive(:pdf?).and_return(true)
        allow(document).to receive(:has_text?).and_return(true)
        expect(document).not_to be_needs_ocr
      end
    end
    
    describe 'metadata management' do
      it 'can add metadata' do
        document.add_metadata('test_key', 'test_value')
        expect(document.metadata.count).to eq(1)
        expect(document.metadata.first.key).to eq('test_key')
        expect(document.metadata.first.value).to eq('test_value')
      end
      
      it 'can store document properties' do
        properties = {
          author: 'John Doe',
          created_date: '2024-01-01',
          pages: 10
        }
        document.store_document_properties(properties)
        expect(document.metadata.count).to eq(3)
        expect(document.metadata.pluck(:key)).to include('document_author', 'document_created_date', 'document_pages')
      end
    end
    
    describe 'callbacks' do
      it 'enqueues processing job after creation' do
        expect(DocumentProcessingJob).to receive(:perform_later).with(kind_of(Document))
        create(:document)
      end
    end
  end
end