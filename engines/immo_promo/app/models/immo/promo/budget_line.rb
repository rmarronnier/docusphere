module Immo
  module Promo
    class BudgetLine < ApplicationRecord
      self.table_name = 'immo_promo_budget_lines'

      belongs_to :budget, class_name: 'Immo::Promo::Budget'

      validates :category, inclusion: {
        in: %w[land_acquisition studies construction_work equipment marketing legal administrative contingency]
      }
      validates :planned_amount_cents, presence: true, numericality: { greater_than: 0 }

      monetize :planned_amount_cents
      monetize :actual_amount_cents, allow_nil: true
      monetize :committed_amount_cents, allow_nil: true
      
      # Alias pour compatibilité
      alias_attribute :amount_cents, :planned_amount_cents
      alias_attribute :spent_amount_cents, :actual_amount_cents

      enum category: {
        land_acquisition: 'land_acquisition',
        studies: 'studies',
        construction_work: 'construction_work',
        equipment: 'equipment',
        marketing: 'marketing',
        legal: 'legal',
        administrative: 'administrative',
        contingency: 'contingency'
      }

      scope :by_category, ->(cat) { where(category: cat) }

      def remaining_amount
        planned_amount - (actual_amount || Money.new(0, 'EUR'))
      end

      def spending_percentage
        return 0 unless planned_amount_cents > 0
        ((actual_amount || Money.new(0, 'EUR')).to_f / planned_amount.to_f * 100).round(2)
      end

      def is_over_budget?
        return false unless actual_amount
        actual_amount > planned_amount
      end
      
      # Méthodes alias pour compatibilité
      def amount
        planned_amount
      end
      
      def spent_amount
        actual_amount
      end
      
      def can_be_deleted?
        # Une ligne budgétaire peut être supprimée s'il n'y a pas de dépenses engagées
        (actual_amount_cents || 0) == 0 && (committed_amount_cents || 0) == 0
      end
    end
  end
end
