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

  describe 'private methods' do
    describe '#classify_by_keywords' do
      it 'returns contract for contract keywords' do
        classification = service.send(:classify_by_keywords, 'contract agreement terms')
        expect(classification).to eq('contract')
      end

      it 'returns report for report keywords' do
        classification = service.send(:classify_by_keywords, 'analysis report findings')
        expect(classification).to eq('report')
      end

      it 'returns other for unmatched content' do
        classification = service.send(:classify_by_keywords, 'random text content')
        expect(classification).to eq('other')
      end
    end

    describe '#extract_emails' do
      it 'extracts valid email addresses' do
        text = 'Contact john@example.com or jane.doe@company.org for more info'
        emails = service.send(:extract_emails, text)
        expect(emails).to contain_exactly('john@example.com', 'jane.doe@company.org')
      end
    end

    describe '#extract_phone_numbers' do
      it 'extracts various phone formats' do
        text = 'Call +33 1 23 45 67 89 or 01.23.45.67.89 or 0123456789'
        phones = service.send(:extract_phone_numbers, text)
        expect(phones.length).to be >= 1
      end
    end

    describe '#extract_amounts' do
      it 'extracts monetary amounts' do
        text = 'Total: €1,500.00 or $2,000.50 or £999.99'
        amounts = service.send(:extract_amounts, text)
        expect(amounts.length).to be >= 2
      end
    end

    describe '#extract_dates' do
      it 'extracts date formats' do
        text = 'Due on 2024-03-15 or 15/03/2024 or March 15, 2024'
        dates = service.send(:extract_dates, text)
        expect(dates.length).to be >= 1
      end
    end
  end
end