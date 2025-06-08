class Immo::Promo::Budget < ApplicationRecord
  self.table_name = 'immo_promo_budgets'
  
  audited

  belongs_to :project, class_name: 'Immo::Promo::Project'
  has_many :budget_lines, class_name: 'Immo::Promo::BudgetLine', dependent: :destroy

  validates :name, presence: true
  validates :budget_type, inclusion: { in: %w[initial revised final] }
  validates :version, presence: true, uniqueness: { scope: :project_id }

  monetize :total_amount_cents
  monetize :spent_amount_cents, allow_nil: true

  # Declare attribute type for enum
  attribute :budget_type, :string
  
  enum budget_type: {
    initial: 'initial',
    revised: 'revised',
    final: 'final'
  }

  scope :current, -> { where(is_current: true) }
  scope :by_type, ->(type) { where(budget_type: type) }

  def remaining_amount
    total_amount - (spent_amount || Money.new(0))
  end

  def spending_percentage
    return 0 unless total_amount.cents > 0
    ((spent_amount || Money.new(0)) / total_amount * 100).round(2)
  end

  def is_over_budget?
    spent_amount && spent_amount > total_amount
  end

  def variance
    (spent_amount || Money.new(0)) - total_amount
  end

  def total_budget_lines_amount
    budget_lines.sum(&:amount)
  end

  def budget_line_by_category(category)
    budget_lines.where(category: category)
  end
end