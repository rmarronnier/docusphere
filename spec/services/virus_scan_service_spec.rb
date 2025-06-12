require 'rails_helper'

RSpec.describe VirusScanService do
  describe '#scan' do
    let(:file_path) { Rails.root.join('spec/fixtures/files/sample.pdf') }
    let(:service) { described_class.new(file_path) }

    it 'returns a clean scan result' do
      result = service.scan
      
      expect(result).to be_a(Hash)
      expect(result[:clean]).to be true
      expect(result[:virus_name]).to be_nil
      expect(result[:scanned_at]).to be_a(Time)
    end
  end

  describe '.scan_file' do
    let(:file_path) { Rails.root.join('spec/fixtures/files/sample.pdf') }

    it 'creates a new instance and scans the file' do
      result = described_class.scan_file(file_path)
      
      expect(result).to be_a(Hash)
      expect(result[:clean]).to be true
    end
  end
end