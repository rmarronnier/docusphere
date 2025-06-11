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
    # Pas de validations obligatoires car les spécifications sont optionnelles
    it 'is valid without required fields' do
      expect(lot_specification).to be_valid
    end
  end

  describe 'enums' do
    it 'defines specification_type enum' do
      expect(lot_specification).to respond_to(:specification_type)
    end
    
    it 'defines category enum' do
      expect(lot_specification).to respond_to(:category)
      expect(Immo::Promo::LotSpecification.categories.keys).to include(
        'apartment', 'house', 'studio', 'commercial'
      )
    end
  end
  
  describe '#has_amenities?' do
    it 'returns true when has any amenity' do
      lot_specification.has_balcony = true
      expect(lot_specification.has_amenities?).to be true
    end
    
    it 'returns false when has no amenities' do
      lot_specification.has_balcony = false
      lot_specification.has_terrace = false
      lot_specification.has_parking = false
      lot_specification.has_storage = false
      expect(lot_specification.has_amenities?).to be false
    end
  end
  
  describe '#total_rooms' do
    it 'returns the number of rooms' do
      lot_specification.rooms = 4
      expect(lot_specification.total_rooms).to eq(4)
    end
    
    it 'returns 0 when rooms is nil' do
      lot_specification.rooms = nil
      expect(lot_specification.total_rooms).to eq(0)
    end
  end
  
  describe '#description' do
    it 'generates a description based on attributes' do
      lot_specification.category = 'apartment'
      lot_specification.rooms = 3
      lot_specification.bedrooms = 2
      lot_specification.has_balcony = true
      
      expect(lot_specification.description).to include('Apartment')
      expect(lot_specification.description).to include('3 pièces')
      expect(lot_specification.description).to include('2 chambres')
      expect(lot_specification.description).to include('balcon')
    end
  end
end