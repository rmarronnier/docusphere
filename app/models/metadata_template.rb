class MetadataTemplate < ApplicationRecord
  belongs_to :organization
  has_many :metadata_fields, dependent: :destroy
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization_id }
  
  accepts_nested_attributes_for :metadata_fields, allow_destroy: true
  
  def field_names
    metadata_fields.pluck(:name)
  end
end