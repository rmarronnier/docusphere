class Immo::Promo::BudgetLine < ApplicationRecord
  self.table_name = 'immo_promo_budget_lines'
  
  belongs_to :budget, class_name: 'Immo::Promo::Budget'

  validates :name, presence: true
  validates :category, inclusion: { 
    in: %w[land_acquisition studies construction_work equipment marketing legal administrative contingency] 
  }
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }

  monetize :amount_cents
  monetize :spent_amount_cents, allow_nil: true

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
    amount - (spent_amount || Money.new(0))
  end

  def spending_percentage
    return 0 unless amount.cents > 0
    ((spent_amount || Money.new(0)) / amount * 100).round(2)
  end

  def is_over_budget?
    spent_amount && spent_amount > amount
  end
end