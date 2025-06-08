require 'rails_helper'

RSpec.describe Basket, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:basket_items).dependent(:destroy) }
    # Basket items are polymorphic - no direct association to items
  end

  describe 'validations' do
    subject { build(:basket) }
    
    it { should validate_presence_of(:name) }
  end

  describe 'factory' do
    it 'creates a valid basket' do
      basket = create(:basket)
      expect(basket).to be_valid
    end

    describe 'with_documents trait' do
      let(:basket) { create(:basket, :with_documents) }
      
      it 'creates a basket with documents' do
        expect(basket.basket_items.count).to eq(3)
      end
    end
  end

  describe 'basket management' do
    let(:basket) { create(:basket) }
    let(:document) { create(:document) }
    
    describe '#add_document' do
      it 'adds a document to the basket' do
        expect { basket.add_document(document) }.to change { basket.basket_items.count }.by(1)
      end
      
      it 'does not add the same document twice' do
        basket.add_document(document)
        expect { basket.add_document(document) }.not_to change { basket.basket_items.count }
      end
    end

    describe '#remove_document' do
      before { basket.add_document(document) }
      
      it 'removes a document from the basket' do
        expect { basket.remove_document(document) }.to change { basket.basket_items.count }.by(-1)
      end
    end

    describe '#document_count' do
      it 'returns the number of documents in the basket' do
        expect(basket.document_count).to eq(0)
        basket.add_document(document)
        expect(basket.document_count).to eq(1)
      end
    end

    describe '#empty?' do
      it 'returns true when basket has no documents' do
        expect(basket.empty?).to be true
      end
      
      it 'returns false when basket has documents' do
        basket.add_document(document)
        expect(basket.empty?).to be false
      end
    end
  end
end