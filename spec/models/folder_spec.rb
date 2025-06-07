require 'rails_helper'

RSpec.describe Folder, type: :model do
  describe 'includes' do
    it 'includes Treeable concern' do
      expect(Folder.included_modules).to include(Treeable)
    end
  end

  describe 'associations' do
    it { should belong_to(:space) }
    it { should have_many(:documents).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:folder) }
    
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug).scoped_to(:space_id) }
    it { should validate_uniqueness_of(:name).scoped_to([:space_id, :parent_id]) }
  end

  describe 'callbacks' do
    describe 'slug generation' do
      context 'when slug is blank' do
        let(:folder) { build(:folder, name: 'Test Folder', slug: '') }
        
        it 'generates slug from name' do
          folder.valid?
          expect(folder.slug).to eq('test-folder')
        end
      end

      context 'when slug is present' do
        let(:folder) { build(:folder, name: 'Test Folder', slug: 'custom-slug') }
        
        it 'does not override existing slug' do
          folder.valid?
          expect(folder.slug).to eq('custom-slug')
        end
      end
    end
  end

  describe 'scopes' do
    let(:space) { create(:space) }
    let!(:folders) { create_list(:folder, 3, space: space) }

    describe '.in_space' do
      it 'returns folders in the specified space' do
        expect(Folder.in_space(space)).to include(*folders)
      end
    end
  end

  describe 'hierarchy methods from Treeable' do
    let(:parent_folder) { create(:folder) }
    let(:child_folder) { create(:folder, parent: parent_folder, space: parent_folder.space) }
    
    describe '#parent_folders' do
      it 'returns the parent hierarchy' do
        expect(child_folder.parent_folders).to include(parent_folder)
      end
    end

    describe '#root?' do
      it 'returns true for root folder' do
        expect(parent_folder.root?).to be true
      end
      
      it 'returns false for child folder' do
        expect(child_folder.root?).to be false
      end
    end

    describe '#full_path' do
      it 'returns the complete path' do
        expect(child_folder.full_path).to eq("#{parent_folder.name}/#{child_folder.name}")
      end
    end
  end

  describe 'factory' do
    it 'creates a valid folder' do
      folder = create(:folder)
      expect(folder).to be_valid
      expect(folder.slug).to be_present
    end

    describe 'with_children trait' do
      let(:folder) { create(:folder, :with_children) }
      
      it 'creates a folder with children' do
        expect(folder.children.count).to eq(3)
      end
    end

    describe 'with_documents trait' do
      let(:folder) { create(:folder, :with_documents) }
      
      it 'creates a folder with documents' do
        expect(folder.documents.count).to eq(5)
      end
    end
  end
end