require 'rails_helper'

RSpec.describe ThumbnailGenerationJob, type: :job do
  include ActiveJob::TestHelper
  
  let(:document) { create(:document, :with_image_file) }
  
  describe '#perform' do
    it 'enqueues the job' do
      expect {
        ThumbnailGenerationJob.perform_later(document.id)
      }.to have_enqueued_job(ThumbnailGenerationJob)
        .with(document.id)
        .on_queue('document_processing')
    end
    
    context 'when document exists' do
      it 'generates thumbnail for the document' do
        expect(document.file).to receive(:attached?).and_return(true)
        expect(document.file).to receive(:blob).and_return(double(content_type: 'image/jpeg'))
        
        # Mock thumbnail generation
        allow_any_instance_of(ThumbnailGenerationJob).to receive(:generate_thumbnail).and_return(true)
        
        ThumbnailGenerationJob.new.perform(document.id)
        
        expect(document.reload.has_thumbnail?).to be true
      end
      
      it 'handles various image formats' do
        %w[image/jpeg image/png image/gif image/webp].each do |content_type|
          document.update!(file_content_type: content_type)
          
          expect {
            ThumbnailGenerationJob.new.perform(document.id)
          }.not_to raise_error
        end
      end
      
      it 'generates thumbnail for PDF documents' do
        document.update!(file_content_type: 'application/pdf')
        
        allow_any_instance_of(ThumbnailGenerationJob).to receive(:extract_pdf_first_page).and_return(true)
        
        ThumbnailGenerationJob.new.perform(document.id)
        
        expect(document.reload.has_thumbnail?).to be true
      end
    end
    
    context 'when document does not exist' do
      it 'logs error and exits gracefully' do
        expect(Rails.logger).to receive(:error).with(/Document not found/)
        
        ThumbnailGenerationJob.new.perform(999999)
      end
    end
    
    context 'when document has no file attached' do
      let(:document_without_file) { create(:document, :with_image_file) }
      
      it 'skips thumbnail generation' do
        # Mock file.attached? to return false
        allow(document_without_file).to receive_message_chain(:file, :attached?).and_return(false)
        allow(Document).to receive(:find).with(document_without_file.id).and_return(document_without_file)
        
        expect(Rails.logger).to receive(:info).with(/No file attached/)
        
        ThumbnailGenerationJob.new.perform(document_without_file.id)
      end
    end
    
    context 'error handling' do
      it 'handles thumbnail generation failures' do
        allow_any_instance_of(ThumbnailGenerationJob).to receive(:generate_thumbnail).and_raise(StandardError, 'Thumbnail failed')
        
        expect(Rails.logger).to receive(:error).with(/Thumbnail generation failed/)
        
        ThumbnailGenerationJob.new.perform(document.id)
        
        expect(document.reload.thumbnail_generation_failed?).to be true
      end
      
      it 'handles image processing errors' do
        allow_any_instance_of(ThumbnailGenerationJob).to receive(:generate_thumbnail).and_raise(MiniMagick::Error)
        
        expect(Rails.logger).to receive(:error).with(/Image processing error/)
        
        ThumbnailGenerationJob.new.perform(document.id)
      end
    end
    
    context 'thumbnail specifications' do
      it 'creates thumbnail with correct dimensions' do
        expect_any_instance_of(ThumbnailGenerationJob).to receive(:resize_image).with(
          anything,
          width: 200,
          height: 200,
          quality: 85
        )
        
        ThumbnailGenerationJob.new.perform(document.id)
      end
      
      it 'optimizes thumbnail file size' do
        allow_any_instance_of(ThumbnailGenerationJob).to receive(:generate_thumbnail) do |job, doc|
          # Verify optimization is applied
          expect(job).to receive(:optimize_image)
          true
        end
        
        ThumbnailGenerationJob.new.perform(document.id)
      end
      
      it 'stores thumbnail as separate attachment' do
        ThumbnailGenerationJob.new.perform(document.id)
        
        expect(document.reload.thumbnail).to be_attached
        expect(document.thumbnail.blob.content_type).to start_with('image/')
      end
    end
    
    context 'performance' do
      it 'processes large images efficiently' do
        # Create document with large image
        large_image = double(byte_size: 10.megabytes)
        allow(document.file).to receive(:blob).and_return(large_image)
        
        start_time = Time.current
        ThumbnailGenerationJob.new.perform(document.id)
        processing_time = Time.current - start_time
        
        expect(processing_time).to be < 5.seconds
      end
      
      it 'uses streaming for large files' do
        expect_any_instance_of(ThumbnailGenerationJob).to receive(:process_in_chunks)
        
        ThumbnailGenerationJob.new.perform(document.id)
      end
    end
  end
  
  describe 'ActiveJob configuration' do
    it 'uses the document_processing queue' do
      expect(ThumbnailGenerationJob.new.queue_name).to eq('document_processing')
    end
    
    it 'has lower priority than other document jobs' do
      expect(ThumbnailGenerationJob.priority).to be < DocumentProcessingJob.priority
    end
  end
end