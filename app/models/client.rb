# frozen_string_literal: true

class Client < ApplicationRecord
  # Un client est géré par une organisation mais n'en fait pas partie
  has_many :client_relationships, dependent: :destroy
  has_many :organizations, through: :client_relationships
  
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[prospect active inactive] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  scope :active, -> { where(status: 'active') }
  scope :prospects, -> { where(status: 'prospect') }
  scope :inactive, -> { where(status: 'inactive') }
  
  # Scope pour une organisation spécifique
  scope :for_organization, ->(org) { joins(:client_relationships).where(client_relationships: { organization: org }) }
  
  def prospect?
    status == 'prospect'
  end
  
  def active?
    status == 'active'
  end
  
  def inactive?
    status == 'inactive'
  end
  
  # Helper pour les tests - première organisation associée
  def organization
    organizations.first
  end
end