module Immo
  module Promo
    class Certification < ApplicationRecord
      self.table_name = 'immo_promo_certifications'

      belongs_to :stakeholder, class_name: 'Immo::Promo::Stakeholder'
      has_one_attached :certificate_document

      validates :name, presence: true
      validates :issuing_body, presence: true

      # Alias for compatibility
      alias_attribute :issuing_authority, :issuing_body

      # Declare attribute type for enum
      attribute :certification_type, :string

      enum certification_type: {
        insurance: 'insurance',
        qualification: 'qualification',
        rge: 'rge',
        environmental: 'environmental'
      }

      scope :valid, -> { where(is_valid: true) }
      scope :expiring_soon, -> { where(expiry_date: Date.current..3.months.from_now) }
      scope :by_type, ->(type) { where(certification_type: type) }

      def is_expired?
        expiry_date && Date.current > expiry_date
      end

      def days_until_expiry
        return nil unless expiry_date
        (expiry_date.to_date - Date.current).to_i
      end

      def is_expiring_soon?
        return false unless expiry_date
        days_until_expiry && days_until_expiry <= 90 && days_until_expiry > 0
      end

      def validity_status
        return 'expired' if is_expired?
        return 'expiring_soon' if is_expiring_soon?
        return 'valid' if is_valid
        'invalid'
      end
    end
  end
end
