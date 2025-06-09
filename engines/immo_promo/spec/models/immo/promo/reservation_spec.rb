require 'rails_helper'

RSpec.describe Immo::Promo::Reservation, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:lot) { create(:immo_promo_lot, project: project) }
  let(:reservation) { create(:immo_promo_reservation, lot: lot) }

  describe 'associations' do
    it { is_expected.to belong_to(:lot).class_name('Immo::Promo::Lot') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:client_name) }
    it { is_expected.to validate_presence_of(:reservation_date) }
  end

  describe 'monetization' do
    it 'monetizes deposit_amount_cents' do
      expect(reservation).to respond_to(:deposit_amount)
      expect(reservation.deposit_amount).to be_a(Money)
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(reservation).to respond_to(:status)
    end
  end

  describe '#is_active?' do
    it 'checks if reservation is active' do
      reservation.update!(status: 'confirmed')
      expect(reservation.is_active?).to be true
      
      reservation.update!(status: 'cancelled')
      expect(reservation.is_active?).to be false
    end
  end
end