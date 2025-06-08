module Immo
  module Promo
    class Contract < ApplicationRecord
      self.table_name = 'immo_promo_contracts'

      include Schedulable
      audited

      belongs_to :project, class_name: 'Immo::Promo::Project'
      belongs_to :stakeholder, class_name: 'Immo::Promo::Stakeholder'
      has_many_attached :contract_documents
      has_many_attached :amendments

      # Alias pour compatibilité
      alias_attribute :reference, :contract_number
      
      validates :reference, presence: true, uniqueness: { scope: :project_id }
      validates :contract_type, inclusion: {
        in: %w[architecture engineering construction subcontract consulting insurance legal]
      }
      validates :status, inclusion: { in: %w[draft negotiation signed active completed terminated] }

      monetize :amount_cents
      monetize :paid_amount_cents, allow_nil: true

      enum contract_type: {
        architecture: 'architecture',
        engineering: 'engineering',
        construction: 'construction',
        subcontract: 'subcontract',
        consulting: 'consulting',
        insurance: 'insurance',
        legal: 'legal'
      }

      enum status: {
        draft: 'draft',
        negotiation: 'negotiation',
        signed: 'signed',
        active: 'active',
        completed: 'completed',
        terminated: 'terminated'
      }

      scope :active_contracts, -> { where(status: [ 'signed', 'active' ]) }
      scope :by_type, ->(type) { where(contract_type: type) }

      def remaining_amount
        amount - (paid_amount || Money.new(0))
      end

      def payment_percentage
        return 0 unless amount.cents > 0
        ((paid_amount || Money.new(0)) / amount * 100).round(2)
      end

      def is_fully_paid?
        paid_amount && paid_amount >= amount
      end

      def days_until_expiry
        return nil unless end_date
        (end_date.to_date - Date.current).to_i
      end

      def is_expired?
        end_date && Date.current > end_date
      end

      def contract_duration_days
        return nil unless start_date && end_date
        (end_date.to_date - start_date.to_date).to_i
      end

      private

      def schedule_required?
        signed? || active?
      end
    end
  end
end
