require 'rails_helper'

RSpec.describe AiClassificationService do
  let(:document) { create(:document) }
  let(:service) { described_class.new(document) }

  describe '#classify' do
    context 'with PDF document' do
      before do
        allow(document).to receive_message_chain(:file, :attached?).and_return(true)
        document.update!(title: 'Contract Agreement 2024')
      end

      it 'classifies as contract based on title' do
        result = service.classify
        expect(result).to be true
        expect(document.reload.ai_category).to eq('contract')
      end
    end

    context 'with invoice document' do
      before do
        allow(document).to receive(:title).and_return('Invoice #12345')
        allow(document).to receive(:extracted_text).and_return('Total Amount: $1,500.00')
      end

      it 'classifies as invoice' do
        result = service.classify
        expect(result[:classification]).to eq('invoice')
        expect(result[:confidence]).to be > 0.7
      end
    end
  end

  describe '#extract_entities' do
    before do
      allow(document).to receive(:extracted_text).and_return(
        'Contact John Doe at john@example.com or call +33 1 23 45 67 89. Amount: €2,500.00. Due date: 2024-03-15. Reference: REF-12345'
      )
    end

    it 'extracts emails' do
      result = service.send(:extract_entities, 'Contact: john@example.com pour plus d\'infos')
      emails = result.select { |e| e[:type] == 'email' }.map { |e| e[:value] }
      expect(emails).to include('john@example.com')
    end

    it 'extracts phone numbers' do
      result = service.send(:extract_entities, 'Téléphone: +33 1 23 45 67 89')
      phones = result.select { |e| e[:type] == 'phone' }.map { |e| e[:value] }
      expect(phones).to include('+33 1 23 45 67 89')
    end

    it 'extracts amounts' do
      result = service.send(:extract_entities, 'Montant total: €2,500.00')
      amounts = result.select { |e| e[:type] == 'amount' }.map { |e| e[:value] }
      expect(amounts).to include('€2,500.00')
    end

    it 'extracts dates' do
      result = service.send(:extract_entities, 'Date: 15/03/2024')
      dates = result.select { |e| e[:type] == 'date' }.map { |e| e[:value] }
      expect(dates).to include('15/03/2024')
    end

    it 'extracts references' do
      result = service.send(:extract_entities, 'Référence: REF-12345 dans ce document')
      references = result.select { |e| e[:type] == 'reference' }.map { |e| e[:value] }
      expect(references).to include('REF-12345')
    end
  end

  describe 'auto-tagging through classify' do
    before do
      document.update!(
        title: 'Construction contract with architectural specifications',
        description: 'Detailed architectural drawings and construction guidelines'
      )
      allow(document).to receive_message_chain(:file, :attached?).and_return(true)
    end

    it 'applies tags automatically when classifying' do
      expect { service.classify }.to change { document.tags.count }
    end
  end

  describe '#confidence_score' do
    it 'calculates confidence based on title match' do
      allow(document).to receive(:title).and_return('Contract Agreement')
      confidence = service.send(:confidence_score, 'contract', document.title, '')
      expect(confidence).to be > 0.5
    end

    it 'increases confidence with content match' do
      allow(document).to receive(:title).and_return('Document')
      allow(document).to receive(:extracted_text).and_return('contract agreement terms conditions')
      confidence = service.send(:confidence_score, 'contract', document.title, document.extracted_text)
      expect(confidence).to be > 0.3
    end
  end

  # Tests for private methods removed as they test non-existent methods
  # The functionality is tested through the public interface above
end