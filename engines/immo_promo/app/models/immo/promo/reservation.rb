module Immo
  module Promo
    class Reservation < ApplicationRecord
      self.table_name = 'immo_promo_reservations'

      belongs_to :lot, class_name: 'Immo::Promo::Lot'

      validates :status, inclusion: { in: %w[pending active confirmed cancelled expired] }
      validates :reservation_date, presence: true
      validates :expiry_date, presence: true
      validates :client_name, presence: true
      validate :expiry_after_reservation

      monetize :deposit_amount_cents, allow_nil: true
      monetize :final_price_cents

      enum status: {
        pending: 'pending',
        active: 'active',
        confirmed: 'confirmed',
        cancelled: 'cancelled',
        expired: 'expired'
      }

      scope :active_reservations, -> { where(status: [ 'pending', 'active', 'confirmed' ]) }
      scope :expiring_soon, -> { where(expiry_date: Date.current..1.week.from_now) }

      def is_expired?
        Date.current > expiry_date && !confirmed?
      end
      
      def is_active?
        %w[pending active confirmed].include?(status)
      end

      def days_until_expiry
        return 0 if is_expired?
        (expiry_date.to_date - Date.current).to_i
      end

      def deposit_percentage
        return 0 unless deposit_amount && final_price && final_price.cents > 0
        (deposit_amount / final_price * 100).round(2)
      end

      def remaining_amount
        final_price - (deposit_amount || Money.new(0))
      end

      private

      def expiry_after_reservation
        return unless reservation_date && expiry_date
        errors.add(:expiry_date, 'must be after reservation date') if expiry_date <= reservation_date
      end
    end
  end
end
