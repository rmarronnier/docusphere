class MetadataTemplate < ApplicationRecord
  belongs_to :organization
  has_many :metadata_fields, dependent: :destroy
  has_many :space_metadata_templates, dependent: :destroy
  has_many :spaces, through: :space_metadata_templates
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization_id }
  
  accepts_nested_attributes_for :metadata_fields, allow_destroy: true
end