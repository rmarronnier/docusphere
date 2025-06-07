module Addressable
  extend ActiveSupport::Concern

  included do
    validates :address, presence: true, if: :address_required?
    validates :city, presence: true, if: :address_required?
    validates :postal_code, presence: true, if: :address_required?
    
    geocoded_by :full_address
    after_validation :geocode, if: ->(obj) { obj.full_address.present? && obj.full_address_changed? }
    
    scope :near_location, ->(latitude, longitude, distance = 50) {
      near([latitude, longitude], distance)
    }
    
    scope :in_city, ->(city) { where(city: city) }
    scope :in_postal_code, ->(postal_code) { where(postal_code: postal_code) }
  end

  def full_address
    [address, city, postal_code, country].compact.join(', ')
  end

  def full_address_changed?
    address_changed? || city_changed? || postal_code_changed? || country_changed?
  end

  def coordinates
    [latitude, longitude] if latitude.present? && longitude.present?
  end

  def distance_to(other_addressable)
    return nil unless coordinates && other_addressable.coordinates
    Geocoder::Calculations.distance_between(coordinates, other_addressable.coordinates)
  end

  private

  def address_required?
    true # Override in including models if needed
  end
end