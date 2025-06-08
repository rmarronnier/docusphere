module Immo
  module Promo
    class PermitCondition < ApplicationRecord
      self.table_name = 'immo_promo_permit_conditions'

      belongs_to :permit, class_name: 'Immo::Promo::Permit'
      has_one_attached :compliance_document

      validates :description, presence: true

      # Declare attribute type for enum
      attribute :condition_type, :string

      enum condition_type: {
        suspensive: 'suspensive',
        prescriptive: 'prescriptive',
        information: 'information',
        technical: 'technical',
        environmental: 'environmental'
      }

      scope :fulfilled, -> { where(is_fulfilled: true) }
      scope :outstanding, -> { where(is_fulfilled: false) }
      scope :by_type, ->(type) { where(condition_type: type) }

      def is_overdue?
        due_date && Date.current > due_date && !is_fulfilled
      end

      def days_until_due
        return nil unless due_date
        (due_date.to_date - Date.current).to_i
      end

      def project
        permit.project
      end
    end
  end
end
