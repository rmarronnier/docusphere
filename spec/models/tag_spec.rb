require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:document_tags).dependent(:destroy) }
    it { should have_many(:documents).through(:document_tags) }
  end

  describe 'validations' do
    subject { build(:tag) }
    
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'factory' do
    it 'creates a valid tag' do
      tag = create(:tag)
      expect(tag).to be_valid
      expect(tag.name).to be_present
    end

    describe 'with_documents trait' do
      let(:tag) { create(:tag, :with_documents) }
      
      it 'creates a tag with documents' do
        expect(tag.documents.count).to eq(5)
      end
    end
  end

  describe 'scopes and methods' do
    let!(:popular_tag) { create(:tag, :with_documents) }
    let!(:empty_tag) { create(:tag) }
    
    describe 'usage statistics' do
      it 'tracks document count correctly' do
        expect(popular_tag.documents.count).to be > 0
        expect(empty_tag.documents.count).to eq(0)
      end
    end
  end
end