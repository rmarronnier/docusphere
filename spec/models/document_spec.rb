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
end