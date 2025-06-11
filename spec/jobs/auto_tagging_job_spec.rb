require 'rails_helper'

RSpec.describe AutoTaggingJob, type: :job do
  let(:document) { create(:document) }

  describe '#perform' do
    it 'processes document for auto-tagging' do
      expect_any_instance_of(DocumentProcessingService).to receive(:apply_auto_tagging)
      
      AutoTaggingJob.new.perform(document)
    end

    it 'extracts content and applies tags based on keywords' do
      document.update!(content: 'This is a contract for software development with confidential information')
      
      AutoTaggingJob.new.perform(document)
      
      tag_names = document.tags.pluck(:name)
      expect(tag_names).to include('contract')
      expect(tag_names).to include('software')
      expect(tag_names).to include('confidential')
    end

    it 'applies tags based on document type' do
      document.update!(document_type: 'invoice')
      
      AutoTaggingJob.new.perform(document)
      
      expect(document.tags.pluck(:name)).to include('invoice')
    end

    it 'applies tags based on file extension' do
      document.update!(file_name: 'presentation.pptx')
      
      AutoTaggingJob.new.perform(document)
      
      expect(document.tags.pluck(:name)).to include('presentation')
    end

    it 'does not duplicate existing tags' do
      existing_tag = create(:tag, name: 'contract', organization: document.space.organization)
      document.tags << existing_tag
      
      document.update!(content: 'This is a contract document')
      
      expect {
        AutoTaggingJob.new.perform(document)
      }.not_to change { document.tags.where(name: 'contract').count }
    end

    it 'handles documents without content gracefully' do
      document.update!(content: nil)
      
      expect {
        AutoTaggingJob.new.perform(document)
      }.not_to raise_error
    end

    it 'creates tags with correct organization' do
      document.update!(content: 'Important project documentation')
      
      AutoTaggingJob.new.perform(document)
      
      document.tags.each do |tag|
        expect(tag.organization).to eq(document.space.organization)
      end
    end

    context 'with AI classification' do
      before do
        document.update!(
          ai_category: 'legal_contract',
          ai_confidence: 0.95
        )
      end

      it 'applies category-specific tags' do
        AutoTaggingJob.new.perform(document)
        
        tag_names = document.tags.pluck(:name)
        expect(tag_names).to include('legal')
        expect(tag_names).to include('contract')
      end

      it 'applies confidence-based tags' do
        AutoTaggingJob.new.perform(document)
        
        tag_names = document.tags.pluck(:name)
        expect(tag_names).to include('ai:high-confidence')
      end
    end

    context 'with metadata' do
      before do
        document.update!(
          metadata: {
            'author' => 'John Doe',
            'department' => 'Legal',
            'project' => 'Project Alpha'
          }
        )
      end

      it 'creates tags from metadata' do
        AutoTaggingJob.new.perform(document)
        
        tag_names = document.tags.pluck(:name)
        expect(tag_names).to include('department:legal')
        expect(tag_names).to include('project:project-alpha')
      end
    end

    it 'logs errors without failing' do
      allow_any_instance_of(DocumentProcessingService).to receive(:apply_auto_tagging).and_raise(StandardError, 'Test error')
      
      expect(Rails.logger).to receive(:error).with(/Failed to auto-tag document/)
      
      expect {
        AutoTaggingJob.new.perform(document)
      }.not_to raise_error
    end
  end

  describe 'job configuration' do
    it 'uses default queue' do
      expect(AutoTaggingJob.new.queue_name).to eq('default')
    end

    it 'can be enqueued' do
      expect {
        AutoTaggingJob.perform_later(document)
      }.to have_enqueued_job(AutoTaggingJob).with(document)
    end

    it 'can be scheduled' do
      expect {
        AutoTaggingJob.set(wait: 5.minutes).perform_later(document)
      }.to have_enqueued_job(AutoTaggingJob).with(document).at(5.minutes.from_now)
    end
  end
end