class Immo::Promo::Stakeholder < ApplicationRecord
  self.table_name = 'immo_promo_stakeholders'
  
  include Addressable
  audited

  belongs_to :project, class_name: 'Immo::Promo::Project'
  has_many :tasks, class_name: 'Immo::Promo::Task', dependent: :nullify
  has_many :contracts, class_name: 'Immo::Promo::Contract', dependent: :destroy
  has_many :certifications, class_name: 'Immo::Promo::Certification', dependent: :destroy

  validates :name, presence: true
  validates :stakeholder_type, inclusion: { 
    in: %w[architect engineer contractor subcontractor consultant control_office client investor legal_advisor] 
  }
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }, allow_blank: true
  validates :phone, presence: true
  validates :siret, length: { is: 14 }, allow_blank: true

  enum stakeholder_type: {
    architect: 'architect',
    engineer: 'engineer',
    contractor: 'contractor',
    subcontractor: 'subcontractor',
    consultant: 'consultant',
    control_office: 'control_office',
    client: 'client',
    investor: 'investor',
    legal_advisor: 'legal_advisor'
  }

  scope :by_type, ->(type) { where(stakeholder_type: type) }
  scope :active, -> { where(is_active: true) }
  scope :with_valid_insurance, -> { joins(:certifications).where(certifications: { certification_type: 'insurance', is_valid: true }) }

  def full_name
    "#{name} (#{stakeholder_type.humanize})"
  end

  def has_valid_insurance?
    certifications.where(certification_type: 'insurance', is_valid: true).exists?
  end

  def has_valid_qualification?
    certifications.where(certification_type: 'qualification', is_valid: true).exists?
  end

  def active_contracts
    contracts.where(status: 'active')
  end

  def can_work_on_project?
    is_active && has_valid_insurance?
  end

  def contact_info
    contact_parts = [email, phone].compact
    contact_parts.join(' | ')
  end

  private

  def address_required?
    false
  end
end