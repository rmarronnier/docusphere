require 'rails_helper'

RSpec.describe Space, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:documents).dependent(:destroy) }
    it { should have_many(:folders).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:space) }
    
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug).scoped_to(:organization_id) }
  end

  describe 'callbacks' do
    describe 'slug generation' do
      context 'when slug is blank' do
        let(:space) { build(:space, name: 'Test Space', slug: '') }
        
        it 'generates slug from name' do
          space.valid?
          expect(space.slug).to eq('test-space')
        end
      end

      context 'when slug is present' do
        let(:space) { build(:space, name: 'Test Space', slug: 'custom-slug') }
        
        it 'does not override existing slug' do
          space.valid?
          expect(space.slug).to eq('custom-slug')
        end
      end
    end
  end

  describe 'factory' do
    it 'creates a valid space' do
      space = create(:space)
      expect(space).to be_valid
      expect(space.slug).to be_present
    end

    describe 'with_folders trait' do
      let(:space) { create(:space, :with_folders) }
      
      it 'creates a space with folders' do
        expect(space.folders.count).to eq(3)
      end
    end

    describe 'with_documents trait' do
      let(:space) { create(:space, :with_documents) }
      
      it 'creates a space with documents' do
        expect(space.documents.count).to eq(10)
      end
    end
  end
end