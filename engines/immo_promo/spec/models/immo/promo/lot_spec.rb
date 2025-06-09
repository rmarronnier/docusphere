require 'rails_helper'

RSpec.describe Immo::Promo::Lot, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:lot) { create(:immo_promo_lot, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
    it { is_expected.to have_many(:reservations).class_name('Immo::Promo::Reservation').dependent(:destroy) }
    it { is_expected.to have_many(:lot_specifications).class_name('Immo::Promo::LotSpecification').dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:lot_number) }
    it { is_expected.to validate_presence_of(:lot_type) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:surface_area).is_greater_than(0) }
  end

  describe 'monetization' do
    it 'monetizes price_cents' do
      expect(lot).to respond_to(:price)
      expect(lot.price).to be_a(Money)
    end
  end

  describe 'enums' do
    it 'defines lot_type enum' do
      expect(lot).to respond_to(:lot_type)
      expect(lot).to respond_to(:status)
    end
  end

  describe 'scopes' do
    let!(:available_lot) { create(:immo_promo_lot, project: project, status: 'available') }
    let!(:reserved_lot) { create(:immo_promo_lot, project: project, status: 'reserved') }

    describe '.available' do
      it 'returns available lots' do
        lots = Immo::Promo::Lot.available
        expect(lots).to include(available_lot)
        expect(lots).not_to include(reserved_lot)
      end
    end
  end

  describe '#is_available?' do
    it 'checks lot availability' do
      lot.update!(status: 'available')
      expect(lot.is_available?).to be true
      
      lot.update!(status: 'reserved')
      expect(lot.is_available?).to be false
    end
  end

  describe '#price_per_sqm' do
    it 'calculates price per square meter' do
      lot.update!(price_cents: 100_000_00, surface_area: 50.0)
      expect(lot.price_per_sqm).to eq(Money.new(2_000_00, 'EUR'))
    end
  end
end