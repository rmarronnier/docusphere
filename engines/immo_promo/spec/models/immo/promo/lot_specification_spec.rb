require 'rails_helper'

RSpec.describe Immo::Promo::LotSpecification, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:lot) { create(:immo_promo_lot, project: project) }
  let(:lot_specification) { create(:immo_promo_lot_specification, lot: lot) }

  describe 'associations' do
    it { is_expected.to belong_to(:lot).class_name('Immo::Promo::Lot') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:specification_type) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe 'enums' do
    it 'defines specification_type enum' do
      expect(lot_specification).to respond_to(:specification_type)
    end
  end
end