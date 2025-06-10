class Space < ApplicationRecord
  include Authorizable
  
  # Spaces don't have direct ownership - managed through authorizations
  owned_by :none
  
  belongs_to :organization
  has_many :documents, dependent: :destroy
  has_many :folders, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  
  before_validation :generate_slug
  
  private
  
  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end
end