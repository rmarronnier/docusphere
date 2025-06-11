require 'rails_helper'

RSpec.describe Documents::FileManagement do
  let(:document) { create(:document) }

  describe 'validations' do
    subject { build(:document) }
    
    it { should validate_presence_of(:file) }
    
    context 'file size validation' do
      let(:document) { build(:document) }
      
      it 'rejects files larger than 100MB' do
        allow(document).to receive(:file_attached?).and_return(true)
        allow(document).to receive(:file_size).and_return(101.megabytes)
        document.valid?
        expect(document.errors[:file_size]).to include('doit être inférieur ou égal à 104857600')
      end
      
      it 'accepts files up to 100MB' do
        allow(document).to receive(:file_attached?).and_return(true)
        allow(document).to receive(:file_size).and_return(100.megabytes)
        expect(document).to be_valid
      end
    end
  end

  describe '#file_attached?' do
    it 'returns true when file is attached' do
      expect(document.file_attached?).to be true
    end
    
    it 'returns false when file is not attached' do
      document = build(:document)
      allow(document.file).to receive(:attached?).and_return(false)
      expect(document.file_attached?).to be false
    end
  end

  describe '#file_size' do
    it 'returns file size in bytes' do
      allow(document.file.blob).to receive(:byte_size).and_return(1024)
      expect(document.file_size).to eq(1024)
    end
    
    it 'returns nil when no file attached' do
      allow(document.file).to receive(:attached?).and_return(false)
      expect(document.file_size).to be_nil
    end
  end

  describe '#file_extension' do
    it 'returns lowercase extension with dot' do
      allow(document.file).to receive(:filename).and_return(ActiveStorage::Filename.new('test.PDF'))
      expect(document.file_extension).to eq('.pdf')
    end
    
    it 'returns nil when no file attached' do
      allow(document.file).to receive(:attached?).and_return(false)
      expect(document.file_extension).to be_nil
    end
  end

  describe '#file_name_without_extension' do
    it 'returns filename without extension' do
      allow(document.file).to receive(:filename).and_return(ActiveStorage::Filename.new('test_document.pdf'))
      allow(document).to receive(:file_extension).and_return('.pdf')
      expect(document.file_name_without_extension).to eq('test_document')
    end
    
    it 'returns nil when no file attached' do
      allow(document.file).to receive(:attached?).and_return(false)
      expect(document.file_name_without_extension).to be_nil
    end
  end

  describe '#human_file_size' do
    it 'formats bytes' do
      allow(document).to receive(:file_size).and_return(512)
      expect(document.human_file_size).to eq('512 B')
    end
    
    it 'formats kilobytes' do
      allow(document).to receive(:file_size).and_return(1536)
      expect(document.human_file_size).to eq('1.5 KB')
    end
    
    it 'formats megabytes' do
      allow(document).to receive(:file_size).and_return(1572864)
      expect(document.human_file_size).to eq('1.5 MB')
    end
    
    it 'formats gigabytes' do
      allow(document).to receive(:file_size).and_return(1610612736)
      expect(document.human_file_size).to eq('1.5 GB')
    end
    
    it 'returns nil when no file size' do
      allow(document).to receive(:file_size).and_return(nil)
      expect(document.human_file_size).to be_nil
    end
  end
end