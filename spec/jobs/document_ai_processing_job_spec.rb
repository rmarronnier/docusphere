require 'rails_helper'

RSpec.describe DocumentAiProcessingJob, type: :job do
  let(:document) { create(:document) }

  describe '#perform' do
    let(:ai_service) { instance_double(AiClassificationService) }

    before do
      allow(AiClassificationService).to receive(:new).with(document).and_return(ai_service)
    end

    it 'processes document with AI classification service' do
      expect(ai_service).to receive(:classify).and_return({
        classification: 'contract',
        confidence: 0.92,
        entities: ['Acme Corp', 'John Doe'],
        key_dates: ['2024-01-01', '2024-12-31']
      })

      DocumentAiProcessingJob.new.perform(document)
    end

    it 'updates document with AI results' do
      allow(ai_service).to receive(:classify).and_return({
        classification: 'invoice',
        confidence: 0.88,
        entities: ['Company XYZ'],
        amounts: ['$1,500.00']
      })

      DocumentAiProcessingJob.new.perform(document)
      document.reload

      expect(document.ai_category).to eq('invoice')
      expect(document.ai_confidence).to eq(0.88)
      expect(document.ai_processed_at).to be_present
    end

    it 'stores extracted entities in metadata' do
      allow(ai_service).to receive(:classify).and_return({
        classification: 'contract',
        confidence: 0.95,
        entities: ['Client A', 'Vendor B'],
        key_dates: ['2024-03-15'],
        amounts: ['€50,000']
      })

      DocumentAiProcessingJob.new.perform(document)
      document.reload

      expect(document.metadata['ai_entities']).to eq(['Client A', 'Vendor B'])
      expect(document.metadata['ai_key_dates']).to eq(['2024-03-15'])
      expect(document.metadata['ai_amounts']).to eq(['€50,000'])
    end

    it 'triggers auto-tagging after AI processing' do
      allow(ai_service).to receive(:classify).and_return({
        classification: 'report',
        confidence: 0.76
      })

      expect(AutoTaggingJob).to receive(:perform_later).with(document)

      DocumentAiProcessingJob.new.perform(document)
    end

    it 'marks document as AI processed' do
      allow(ai_service).to receive(:classify).and_return({
        classification: 'memo',
        confidence: 0.65
      })

      expect(document).to receive(:mark_as_ai_processed!).with(
        category: 'memo',
        confidence: 0.65
      )

      DocumentAiProcessingJob.new.perform(document)
    end

    context 'when document is not AI processable' do
      before do
        allow(document).to receive(:ai_processable?).and_return(false)
      end

      it 'skips processing' do
        expect(ai_service).not_to receive(:classify)
        
        DocumentAiProcessingJob.new.perform(document)
      end

      it 'logs skip reason' do
        expect(Rails.logger).to receive(:info).with(/Document .* is not AI processable/)
        
        DocumentAiProcessingJob.new.perform(document)
      end
    end

    context 'when AI service fails' do
      before do
        allow(ai_service).to receive(:classify).and_raise(StandardError, 'AI service error')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to process document .* with AI/)
        
        DocumentAiProcessingJob.new.perform(document)
      end

      it 'does not update document AI fields' do
        DocumentAiProcessingJob.new.perform(document)
        document.reload

        expect(document.ai_category).to be_nil
        expect(document.ai_processed_at).to be_nil
      end

      it 'does not trigger auto-tagging' do
        expect(AutoTaggingJob).not_to receive(:perform_later)
        
        DocumentAiProcessingJob.new.perform(document)
      end
    end

    context 'with low confidence results' do
      before do
        allow(ai_service).to receive(:classify).and_return({
          classification: 'unknown',
          confidence: 0.15
        })
      end

      it 'still updates document with results' do
        DocumentAiProcessingJob.new.perform(document)
        document.reload

        expect(document.ai_category).to eq('unknown')
        expect(document.ai_confidence).to eq(0.15)
      end

      it 'adds low confidence flag to metadata' do
        DocumentAiProcessingJob.new.perform(document)
        document.reload

        expect(document.metadata['ai_low_confidence']).to be true
      end
    end

    context 'with compliance detection' do
      before do
        allow(ai_service).to receive(:classify).and_return({
          classification: 'contract',
          confidence: 0.91,
          compliance_flags: ['gdpr', 'pci']
        })
      end

      it 'stores compliance information' do
        DocumentAiProcessingJob.new.perform(document)
        document.reload

        expect(document.metadata['ai_compliance_flags']).to eq(['gdpr', 'pci'])
      end

      it 'triggers compliance notification if needed' do
        expect(NotificationService).to receive(:notify_compliance_issue).with(document, ['gdpr', 'pci'])
        
        DocumentAiProcessingJob.new.perform(document)
      end
    end
  end

  describe 'job configuration' do
    it 'uses low priority queue' do
      expect(DocumentAiProcessingJob.new.queue_name).to eq('low')
    end

    it 'can be enqueued' do
      expect {
        DocumentAiProcessingJob.perform_later(document)
      }.to have_enqueued_job(DocumentAiProcessingJob).with(document).on_queue('low')
    end

    it 'retries on failure' do
      allow(AiClassificationService).to receive(:new).and_raise(StandardError)
      
      expect {
        DocumentAiProcessingJob.perform_now(document)
      }.not_to raise_error
    end
  end
end