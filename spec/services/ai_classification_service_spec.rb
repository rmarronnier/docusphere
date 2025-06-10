require 'rails_helper'

RSpec.describe AiClassificationService do
  let(:document) { create(:document) }
  let(:service) { described_class.new(document) }

  describe '#classify' do
    context 'with PDF document' do
      before do
        allow(document).to receive(:file_content_type).and_return('application/pdf')
        allow(document).to receive(:title).and_return('Contract Agreement 2024')
      end

      it 'classifies as contract based on title' do
        result = service.classify
        expect(result[:classification]).to eq('contract')
        expect(result[:confidence]).to be > 0.5
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
      result = service.extract_entities
      expect(result[:emails]).to include('john@example.com')
    end

    it 'extracts phone numbers' do
      result = service.extract_entities
      expect(result[:phones]).to include('+33 1 23 45 67 89')
    end

    it 'extracts amounts' do
      result = service.extract_entities
      expect(result[:amounts]).to include('€2,500.00')
    end

    it 'extracts dates' do
      result = service.extract_entities
      expect(result[:dates]).to include('2024-03-15')
    end

    it 'extracts references' do
      result = service.extract_entities
      expect(result[:references]).to include('REF-12345')
    end
  end

  describe '#suggest_tags' do
    before do
      allow(document).to receive(:title).and_return('Construction Contract for Building Project')
      allow(document).to receive(:extracted_text).and_return('architectural plans construction materials permit')
    end

    it 'suggests relevant tags based on content' do
      tags = service.suggest_tags
      expect(tags).to include('construction', 'contract', 'architectural')
    end

    it 'returns unique tags' do
      tags = service.suggest_tags
      expect(tags.uniq).to eq(tags)
    end

    it 'limits number of suggested tags' do
      tags = service.suggest_tags
      expect(tags.length).to be <= 10
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