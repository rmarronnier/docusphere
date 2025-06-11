require 'rails_helper'

RSpec.describe Documents::AiProcessable do
  let(:document) { create(:document) }

  describe 'AI processing' do
    describe '#ai_processed?' do
      it 'returns false when not processed' do
        document.ai_processed_at = nil
        expect(document.ai_processed?).to be false
      end

      it 'returns true when processed' do
        document.ai_processed_at = Time.current
        expect(document.ai_processed?).to be true
      end
    end

    describe '#mark_as_ai_processed!' do
      it 'sets ai_processed_at timestamp' do
        expect(document.ai_processed_at).to be_nil
        document.mark_as_ai_processed!
        expect(document.ai_processed_at).to be_present
      end

      it 'updates AI classification data' do
        document.mark_as_ai_processed!(category: 'contract', confidence: 0.95)
        expect(document.ai_category).to eq('contract')
        expect(document.ai_confidence).to eq(0.95)
      end
    end

    describe '#ai_processable?' do
      it 'returns true for supported content types' do
        allow(document).to receive(:content_type).and_return('application/pdf')
        expect(document.ai_processable?).to be true
      end

      it 'returns false for unsupported content types' do
        allow(document).to receive(:content_type).and_return('application/octet-stream')
        expect(document.ai_processable?).to be false
      end

      it 'returns false when file is not attached' do
        allow(document.file).to receive(:attached?).and_return(false)
        expect(document.ai_processable?).to be false
      end
    end

    describe '#ai_processing_status' do
      context 'when not processed' do
        it 'returns pending when processable' do
          allow(document).to receive(:ai_processable?).and_return(true)
          document.ai_processed_at = nil
          expect(document.ai_processing_status).to eq('pending')
        end

        it 'returns not_applicable when not processable' do
          allow(document).to receive(:ai_processable?).and_return(false)
          expect(document.ai_processing_status).to eq('not_applicable')
        end
      end

      context 'when processed' do
        before { document.ai_processed_at = Time.current }

        it 'returns completed' do
          expect(document.ai_processing_status).to eq('completed')
        end
      end
    end

    describe '#ai_insights' do
      before do
        document.ai_processed_at = Time.current
        document.ai_category = 'contract'
        document.ai_confidence = 0.85
        document.metadata['ai_entities'] = ['Acme Corp', 'John Doe']
        document.metadata['ai_key_dates'] = ['2024-01-01', '2024-12-31']
      end

      it 'returns comprehensive AI insights' do
        insights = document.ai_insights
        
        expect(insights[:processed]).to be true
        expect(insights[:category]).to eq('contract')
        expect(insights[:confidence]).to eq(0.85)
        expect(insights[:entities]).to eq(['Acme Corp', 'John Doe'])
        expect(insights[:key_dates]).to eq(['2024-01-01', '2024-12-31'])
      end

      it 'returns empty insights when not processed' do
        document.ai_processed_at = nil
        insights = document.ai_insights
        
        expect(insights[:processed]).to be false
        expect(insights[:category]).to be_nil
      end
    end

    describe '#should_auto_process?' do
      it 'returns true for small processable files' do
        allow(document).to receive(:ai_processable?).and_return(true)
        allow(document).to receive(:file_size).and_return(5.megabytes)
        expect(document.should_auto_process?).to be true
      end

      it 'returns false for large files' do
        allow(document).to receive(:ai_processable?).and_return(true)
        allow(document).to receive(:file_size).and_return(15.megabytes)
        expect(document.should_auto_process?).to be false
      end

      it 'returns false when already processed' do
        document.ai_processed_at = Time.current
        expect(document.should_auto_process?).to be false
      end
    end
  end
end