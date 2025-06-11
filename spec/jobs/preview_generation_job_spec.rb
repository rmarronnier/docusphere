require 'rails_helper'

RSpec.describe PreviewGenerationJob, type: :job do
  include ActiveJob::TestHelper
  
  let(:document) { create(:document, :with_pdf_file) }
  
  describe '#perform' do
    it 'enqueues the job' do
      expect {
        PreviewGenerationJob.perform_later(document.id)
      }.to have_enqueued_job(PreviewGenerationJob)
        .with(document.id)
        .on_queue('document_processing')
    end
    
    context 'when document exists' do
      it 'generates preview images for the document' do
        # Allow multiple calls to attached? since it's called in perform and generate_preview
        allow(document.file).to receive(:attached?).and_return(true)
        allow(document.file).to receive(:blob).and_return(double(content_type: 'application/pdf'))
        
        # Mock the size generation methods
        allow_any_instance_of(PreviewGenerationJob).to receive(:generate_preview_size).and_return(true)
        
        PreviewGenerationJob.new.perform(document.id)
        
        expect(document.reload.processed?).to be true
      end
      
      it 'handles different document types' do
        # Create a document with office document type
        office_doc = create(:word_document)
        
        expect {
          PreviewGenerationJob.new.perform(office_doc.id)
        }.not_to raise_error
      end
      
      it 'sets processing status during generation' do
        allow_any_instance_of(PreviewGenerationJob).to receive(:generate_preview) do |job, doc|
          expect(doc.processing?).to be true
          true
        end
        
        PreviewGenerationJob.new.perform(document.id)
      end
    end
    
    context 'when document does not exist' do
      it 'logs error and exits gracefully' do
        expect(Rails.logger).to receive(:error).with(/Document not found/)
        
        PreviewGenerationJob.new.perform(999999)
      end
    end
    
    context 'when document has no file attached' do
      let(:document_without_file) { create(:document, :without_file) }
      
      it 'skips preview generation' do
        expect(Rails.logger).to receive(:info).with(/No file attached/)
        
        PreviewGenerationJob.new.perform(document_without_file.id)
      end
    end
    
    context 'error handling' do
      it 'handles preview generation failures' do
        allow_any_instance_of(PreviewGenerationJob).to receive(:generate_preview).and_raise(StandardError, 'Preview failed')
        
        expect(Rails.logger).to receive(:error).with(/Preview generation failed/)
        
        expect {
          PreviewGenerationJob.new.perform(document.id)
        }.to raise_error(StandardError, 'Preview failed')
        
        expect(document.reload.failed?).to be true
      end
      
      it 'retries on transient failures' do
        allow_any_instance_of(PreviewGenerationJob).to receive(:generate_preview).and_raise(Net::ReadTimeout)
        
        expect {
          PreviewGenerationJob.new.perform(document.id)
        }.to raise_error(Net::ReadTimeout)
        
        # Job should be configured for retry
        expect(PreviewGenerationJob.new.class.retry_on).to include(Net::ReadTimeout)
      end
    end
    
    context 'preview formats' do
      it 'generates multiple preview sizes' do
        sizes = [:thumbnail, :medium, :large]
        
        sizes.each do |size|
          expect_any_instance_of(PreviewGenerationJob).to receive(:generate_preview_size).with(document, size)
        end
        
        PreviewGenerationJob.new.perform(document.id)
      end
      
      it 'stores preview metadata' do
        PreviewGenerationJob.new.perform(document.id)
        
        document.reload
        expect(document.metadata.find_by(key: 'preview_generated_at')).to be_present
        expect(document.metadata.find_by(key: 'preview_sizes')&.value).to eq(['thumbnail', 'medium', 'large'].to_json)
      end
    end
  end
  
  describe 'ActiveJob configuration' do
    it 'uses the document_processing queue' do
      expect(PreviewGenerationJob.new.queue_name).to eq('document_processing')
    end
    
    it 'has retry configuration' do
      expect(PreviewGenerationJob.retry_on).to include(StandardError)
    end
    
    it 'has discard configuration for permanent failures' do
      expect(PreviewGenerationJob.discard_on).to include(ActiveRecord::RecordNotFound)
    end
  end
end