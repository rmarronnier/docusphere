module Immo
  module Promo
    class Lot < ApplicationRecord
      self.table_name = 'immo_promo_lots'

      audited

      belongs_to :project, class_name: 'Immo::Promo::Project'
      has_many :lot_specifications, class_name: 'Immo::Promo::LotSpecification', dependent: :destroy
      has_many :reservations, class_name: 'Immo::Promo::Reservation', dependent: :destroy
      has_many_attached :plans
      has_many_attached :technical_sheets

      validates :lot_number, presence: true, uniqueness: { scope: :project_id }
      validates :lot_type, inclusion: {
        in: %w[apartment house commercial_unit parking_space storage_unit office]
      }
      validates :status, inclusion: {
        in: %w[planned under_construction completed reserved sold]
      }
      validates :surface_area, presence: true, numericality: { greater_than: 0 }
      validates :floor, presence: true, numericality: { greater_than_or_equal_to: -3 }

      monetize :price_cents, allow_nil: true

      # Alias for compatibility
      alias_attribute :reference, :lot_number
      alias_attribute :floor_level, :floor
      alias_attribute :base_price_cents, :price_cents
      alias_attribute :final_price_cents, :price_cents
      alias_attribute :base_price, :price
      alias_attribute :final_price, :price

      enum lot_type: {
        apartment: 'apartment',
        house: 'house',
        commercial_unit: 'commercial_unit',
        parking_space: 'parking_space',
        storage_unit: 'storage_unit',
        office: 'office'
      }

      enum status: {
        planned: 'planned',
        under_construction: 'under_construction',
        completed: 'completed',
        reserved: 'reserved',
        sold: 'sold'
      }

      scope :by_type, ->(type) { where(lot_type: type) }
      scope :by_status, ->(status) { where(status: status) }
      scope :available, -> { where(status: [ 'planned', 'under_construction', 'completed' ]) }
      scope :residential, -> { where(lot_type: [ 'apartment', 'house' ]) }
      scope :commercial, -> { where(lot_type: [ 'commercial_unit', 'office' ]) }
      scope :by_floor, ->(floor) { where(floor_level: floor) }

      def display_name
        "#{lot_type.humanize} #{reference}"
      end

      def is_available?
        %w[planned under_construction completed].include?(status)
      end

      def price_per_sqm
        return nil unless final_price && surface_area > 0
        final_price / surface_area
      end

      def has_active_reservation?
        reservations.where(status: 'active').exists?
      end

      def current_reservation
        reservations.where(status: 'active').first
      end

      def completion_percentage
        case status
        when 'planned' then 0
        when 'under_construction' then 50
        when 'completed', 'reserved', 'sold' then 100
        else 0
        end
      end

      def rooms_description
        return 'N/A' unless rooms_count
        case lot_type
        when 'apartment', 'house'
          "T#{rooms_count}"
        when 'commercial_unit', 'office'
          "#{rooms_count} espaces"
        else
          rooms_count.to_s
        end
      end

      def has_balcony_or_terrace?
        balcony_area && balcony_area > 0
      end

      def total_area
        surface_area + (balcony_area || 0)
      end
    end
  end
end
