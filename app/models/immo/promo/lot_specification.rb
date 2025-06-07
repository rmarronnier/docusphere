class Immo::Promo::LotSpecification < ApplicationRecord
  self.table_name = 'immo_promo_lot_specifications'
  
  belongs_to :lot, class_name: 'Immo::Promo::Lot'

  validates :specification_type, inclusion: { 
    in: %w[finishes equipment technical_requirements environmental accessibility] 
  }
  validates :name, presence: true

  enum specification_type: {
    finishes: 'finishes',
    equipment: 'equipment',
    technical_requirements: 'technical_requirements',
    environmental: 'environmental',
    accessibility: 'accessibility'
  }

  scope :by_type, ->(type) { where(specification_type: type) }
  scope :standard, -> { where(is_standard: true) }
  scope :custom, -> { where(is_standard: false) }

  def display_name
    "#{specification_type.humanize}: #{name}"
  end
end