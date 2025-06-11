require 'rails_helper'

RSpec.describe AiClassificationService do
  let(:document) { create(:document) }
  let(:service) { described_class.new(document) }

  describe '#classify' do
    context 'with PDF document' do
      before do
        # Create a proper file attachment
        document.file.attach(
          io: StringIO.new("Sample PDF content"),
          filename: 'contract.pdf',
          content_type: 'application/pdf'
        )
        document.update!(title: 'Contract Agreement 2024')
      end

      it 'classifies as contract based on title' do
        result = service.classify
        # Debug the error if classification fails
        if !result[:success]
          puts "Classification failed: #{result[:error]}"
        end
        expect(result[:success]).to be true
        expect(result[:classification]).to eq('contract')
        expect(document.reload.ai_category).to eq('contract')
      end
    end

    context 'with invoice document' do
      before do
        document.file.attach(
          io: StringIO.new("Invoice content"),
          filename: 'invoice.pdf',
          content_type: 'application/pdf'
        )
        document.update!(
          title: 'Invoice #12345',
          extracted_text: 'Facture n°12345. Total Amount: €1,500.00 TTC. Montant HT: €1,250.00. TVA: €250.00'
        )
      end

      it 'classifies as invoice' do
        result = service.classify
        expect(result[:success]).to be true
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
      # Ensure document has proper associations for tagging
      document.file.attach(
        io: StringIO.new("Contract content"),
        filename: 'contract.pdf',
        content_type: 'application/pdf'
      )
      document.update!(
        title: 'Contrat de construction avec spécifications architecturales',
        description: 'Plans architecturaux détaillés et directives de construction'
      )
      # Ensure document has a space with organization for tagging
      expect(document.space).to be_present
      expect(document.space.organization).to be_present
    end

    it 'applies tags automatically when classifying' do
      result = service.classify
      # Debug information
      puts "Classification result: #{result[:classification]} (confidence: #{result[:confidence]})"
      puts "Tags applied: #{result[:tags_applied].inspect}"
      puts "Document tags count: #{document.tags.count}"
      
      expect(result[:success]).to be true
      expect(result[:classification]).to eq('contract')
      expect(result[:confidence]).to be > 0.5
      # The document should be tagged with at least the type tag
      expect(result[:tags_applied]).to include("type:contract")
    end
  end

  describe '#confidence_score' do
    it 'calculates confidence based on title match' do
      # 'Contrat de service' should match 'contrat' keyword
      confidence = service.confidence_score('contract', 'Contrat de service', '')
      expect(confidence).to be > 0.3
    end

    it 'increases confidence with content match' do
      # Multiple contract-related keywords in content should increase confidence
      confidence = service.confidence_score('contract', 'Document', 'contrat accord convention clause obligation')
      expect(confidence).to be > 0.3
    end
  end

  # Tests for private methods removed as they test non-existent methods
  # The functionality is tested through the public interface above
end