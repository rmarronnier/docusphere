class Immo::Promo::Permit < ApplicationRecord
  self.table_name = 'immo_promo_permits'
  
  include Schedulable
  include WorkflowManageable
  audited

  belongs_to :project, class_name: 'Immo::Promo::Project'
  has_many :permit_conditions, class_name: 'Immo::Promo::PermitCondition', dependent: :destroy
  has_many_attached :permit_documents
  has_many_attached :response_documents

  validates :permit_type, presence: true, inclusion: { 
    in: %w[urban_planning construction demolition environmental modification declaration] 
  }
  validates :status, inclusion: { 
    in: %w[draft submitted under_review additional_info_requested approved denied appeal] 
  }
  validates :reference_number, presence: true, uniqueness: { scope: :project_id }
  validates :authority, presence: true

  enum permit_type: {
    urban_planning: 'urban_planning',
    construction: 'construction',
    demolition: 'demolition',
    environmental: 'environmental',
    modification: 'modification',
    declaration: 'declaration'
  }

  enum status: {
    draft: 'draft',
    submitted: 'submitted',
    under_review: 'under_review',
    additional_info_requested: 'additional_info_requested',
    approved: 'approved',
    denied: 'denied',
    appeal: 'appeal'
  }

  scope :by_type, ->(type) { where(permit_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :critical, -> { where(permit_type: ['construction', 'urban_planning']) }
  scope :expiring_soon, -> { where(expiry_date: Date.current..3.months.from_now) }

  def days_until_expiry
    return nil unless expiry_date
    (expiry_date.to_date - Date.current).to_i
  end

  def is_expired?
    expiry_date && Date.current > expiry_date
  end

  def is_expiring_soon?
    return false unless expiry_date
    days_until_expiry <= 90 && days_until_expiry > 0
  end

  def review_period_remaining
    return nil unless submission_date && expected_decision_date
    (expected_decision_date.to_date - Date.current).to_i
  end

  def can_start_construction?
    approved? && permit_type == 'construction'
  end

  def has_conditions?
    permit_conditions.exists?
  end

  def outstanding_conditions
    permit_conditions.where(is_fulfilled: false)
  end

  def all_conditions_fulfilled?
    permit_conditions.all?(&:is_fulfilled)
  end

  def permit_name
    "#{permit_type.humanize} - #{reference_number}"
  end

  private

  def schedule_required?
    submitted? || under_review?
  end
end