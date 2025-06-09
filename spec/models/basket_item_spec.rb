require 'rails_helper'

RSpec.describe BasketItem, type: :model do
  describe 'associations' do
    it { should belong_to(:basket) }
    it { should belong_to(:item) }
  end

  describe 'validations' do
    subject { create(:basket_item) }
    
    it { should validate_uniqueness_of(:item_id).scoped_to([:basket_id, :item_type]) }
    it { should validate_presence_of(:position) }
  end

  describe 'instance methods' do
    let(:document) { create(:document) }
    let(:basket) { create(:basket) }
    let(:basket_item) { create(:basket_item, basket: basket, item: document) }

    describe '#document' do
      context 'when item is a Document' do
        it 'returns the document' do
          expect(basket_item.document).to eq(document)
        end
      end

      context 'when item is not a Document' do
        let(:folder) { create(:folder) }
        let(:basket_item) { create(:basket_item, basket: basket, item: folder) }

        it 'returns nil' do
          expect(basket_item.document).to be_nil
        end
      end
    end

    describe '#document?' do
      context 'when item is a Document' do
        it 'returns true' do
          expect(basket_item.document?).to be true
        end
      end

      context 'when item is not a Document' do
        let(:folder) { create(:folder) }
        let(:basket_item) { create(:basket_item, basket: basket, item: folder) }

        it 'returns false' do
          expect(basket_item.document?).to be false
        end
      end
    end
  end
end