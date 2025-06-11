require 'rails_helper'

RSpec.describe 'Thumbnail Generation Integration', type: :integration do
  include ActiveJob::TestHelper
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  
  describe 'complete thumbnail generation workflow' do
    context 'when uploading a PDF document' do
      let(:pdf_content) { "%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj" }
      let(:document) do
        doc = build(:document, space: space, uploaded_by: user)
        doc.file.attach(
          io: StringIO.new(pdf_content),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        doc.save!
        doc
      end
      
      it 'can be processed by thumbnail generation job' do
        expect {
          ThumbnailGenerationJob.perform_later(document.id)
        }.to have_enqueued_job(ThumbnailGenerationJob).with(document.id)
      end
      
      it 'can be processed by preview generation job' do
        expect {
          PreviewGenerationJob.perform_later(document.id)  
        }.to have_enqueued_job(PreviewGenerationJob).with(document.id)
      end
      
      context 'after job execution' do
        before do
          # Simulate job execution
          allow_any_instance_of(ThumbnailGenerationJob).to receive(:resize_image).and_return(true)
          allow_any_instance_of(ThumbnailGenerationJob).to receive(:extract_pdf_first_page).and_return(true)
          allow_any_instance_of(PreviewGenerationJob).to receive(:generate_preview_size).and_return(true)
          
          # Execute jobs directly
          PreviewGenerationJob.new.perform(document.id)
        end
        
        it 'marks document as processed' do
          expect(document.reload.processed?).to be true
        end
        
        it 'generates metadata entries' do
          expect(document.metadata.find_by(key: 'preview_generated_at')).to be_present
          expect(document.metadata.find_by(key: 'preview_sizes')).to be_present
        end
      end
    end
    
    context 'when uploading an image document' do
      let(:document) do
        doc = build(:document, space: space, uploaded_by: user)
        doc.file.attach(
          io: StringIO.new('fake image content'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        doc.save!
        doc
      end
      
      it 'uses image-specific processing' do
        job = PreviewGenerationJob.new
        allow(job).to receive(:generate_image_preview_size).and_return(true)
        
        job.perform(document.id)
        
        expect(job).to have_received(:generate_image_preview_size).at_least(:once)
      end
    end
    
    context 'when uploading an office document' do
      let(:document) { create(:word_document, space: space, uploaded_by: user) }
      
      it 'creates placeholder preview' do
        job = PreviewGenerationJob.new
        allow(job).to receive(:create_placeholder_preview).and_return(true)
        
        job.perform(document.id)
        
        expect(job).to have_received(:create_placeholder_preview)
      end
    end
  end
  
  describe 'thumbnail URL generation' do
    let(:document) { create(:document, :with_pdf_file, space: space, uploaded_by: user) }
    
    it 'provides fallback icon when no thumbnail' do
      expect(document.thumbnail_url).to match(/pdf-icon.*\.svg/)
    end
    
    context 'with thumbnail attached' do
      before do
        document.thumbnail.attach(
          io: StringIO.new('fake thumbnail'),
          filename: 'thumb.jpg',
          content_type: 'image/jpeg'
        )
      end
      
      it 'returns thumbnail blob path' do
        expect(document.thumbnail_url).to include('rails/active_storage/blobs')
      end
    end
    
    it 'handles different file types correctly' do
      # Test each file type
      {
        'application/pdf' => /pdf-icon/,
        'application/vnd.ms-excel' => /excel-icon/,
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => /word-icon/,
        'application/zip' => /zip-icon/,
        'text/plain' => /txt-icon/,
        'application/unknown' => /generic-icon/
      }.each do |content_type, expected_icon|
        allow(document).to receive(:file_content_type).and_return(content_type)
        expect(document.icon_for_content_type).to match(expected_icon)
      end
    end
  end
  
  describe 'variant configurations' do
    let(:document) { create(:image_document, space: space, uploaded_by: user) }
    
    it 'provides different size variants' do
      [:thumb, :medium, :large].each do |size|
        variant_config = ActiveStorageVariants::THUMBNAIL_VARIANTS[size]
        expect(variant_config).to be_present
        expect(variant_config[:resize_to_limit]).to be_present
      end
    end
    
    it 'includes special variants for UI needs' do
      expect(ActiveStorageVariants::SPECIAL_VARIANTS).to include(
        :grid_thumb, :preview_full, :mobile_thumb, :mobile_preview
      )
    end
  end
  
  describe 'error handling' do
    let(:document) { create(:document, :with_pdf_file, space: space, uploaded_by: user) }
    
    it 'handles missing files gracefully' do
      doc = build(:document, :without_file, space: space, uploaded_by: user)
      doc.save!
      
      expect(doc.thumbnail_url).to match(/document-placeholder/)
    end
    
    it 'handles non-existent documents gracefully' do
      job = ThumbnailGenerationJob.new
      
      # This should not raise an error because of discard_on ActiveRecord::RecordNotFound
      expect {
        job.perform(999999)
      }.not_to raise_error
    end
  end
end