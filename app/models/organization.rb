class Organization < ApplicationRecord
  has_many :spaces, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :metadata_templates, dependent: :destroy
  has_many :workflow_templates, dependent: :destroy
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  
  before_validation :generate_slug
  
  private
  
  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end
end