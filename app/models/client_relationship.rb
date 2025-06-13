# frozen_string_literal: true

class ClientRelationship < ApplicationRecord
  belongs_to :client
  belongs_to :organization
  
  validates :client_id, uniqueness: { scope: :organization_id }
  validates :relationship_type, inclusion: { in: %w[managed prospect partner] }
  
  scope :managed, -> { where(relationship_type: 'managed') }
  scope :prospects, -> { where(relationship_type: 'prospect') }
  scope :partners, -> { where(relationship_type: 'partner') }
end