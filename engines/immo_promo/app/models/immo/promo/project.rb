class Immo::Promo::Project < ApplicationRecord
  self.table_name = 'immo_promo_projects'
  
  include Addressable
  include Schedulable
  # include WorkflowManageable # Temporarily disabled - model mismatch
  include Authorizable
  audited

  belongs_to :organization
  belongs_to :project_manager, class_name: 'User', optional: true
  has_many :phases, class_name: 'Immo::Promo::Phase', dependent: :destroy
  has_many :lots, class_name: 'Immo::Promo::Lot', dependent: :destroy
  has_many :stakeholders, class_name: 'Immo::Promo::Stakeholder', dependent: :destroy
  has_many :permits, class_name: 'Immo::Promo::Permit', dependent: :destroy
  has_many :budgets, class_name: 'Immo::Promo::Budget', dependent: :destroy
  has_many :contracts, class_name: 'Immo::Promo::Contract', dependent: :destroy
  has_many :risks, class_name: 'Immo::Promo::Risk', dependent: :destroy
  has_many :milestones, class_name: 'Immo::Promo::Milestone', dependent: :destroy
  has_many :progress_reports, class_name: 'Immo::Promo::ProgressReport', dependent: :destroy
  
  has_many_attached :technical_documents
  has_many_attached :administrative_documents
  has_many_attached :financial_documents

  validates :name, presence: true
  validates :project_type, presence: true
  validates :status, presence: true
  
  before_validation :set_defaults
  
  private
  
  def set_defaults
    self.slug ||= name.parameterize if name.present?
    self.reference_number ||= "PROJ-#{organization.id}-#{Time.current.strftime('%Y%m%d%H%M%S')}" if organization.present?
  end
  
  public

  monetize :total_budget_cents, allow_nil: true
  monetize :current_budget_cents, allow_nil: true
  
  # Alias for Schedulable concern compatibility
  alias_attribute :end_date, :expected_completion_date

  enum project_type: { 
    residential: 'residential', 
    commercial: 'commercial', 
    mixed: 'mixed',
    office: 'office',
    retail: 'retail',
    industrial: 'industrial' 
  }
  
  enum status: { 
    planning: 'planning',
    pre_construction: 'pre_construction',
    construction: 'construction',
    finishing: 'finishing',
    delivered: 'delivered',
    completed: 'completed',
    cancelled: 'cancelled'
  }

  scope :active, -> { where.not(status: ['completed', 'cancelled']) }
  scope :by_type, ->(type) { where(project_type: type) }
  scope :by_manager, ->(manager) { where(project_manager: manager) }

  def completion_percentage
    return 0 if phases.empty?
    completed_phases = phases.where(status: 'completed').count
    (completed_phases.to_f / phases.count * 100).round(2)
  end

  def is_delayed?
    return false unless end_date
    phases.where('end_date > ? AND status != ?', end_date, 'completed').exists?
  end

  def total_surface_area
    lots.sum(:surface_area)
  rescue ActiveRecord::StatementInvalid
    0
  end

  def can_start_construction?
    permits.where(permit_type: 'construction', status: 'approved').exists?
  rescue ActiveRecord::StatementInvalid
    false
  end

  private

  def address_required?
    true
  end

  def schedule_required?
    true
  end
end