class MetadataTemplate < ApplicationRecord
  belongs_to :organization
  has_many :metadata_fields, dependent: :destroy
  has_many :document_metadata, class_name: 'DocumentMetadata', dependent: :destroy
  has_many :documents, through: :document_metadata
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization_id }
  
  accepts_nested_attributes_for :metadata_fields, allow_destroy: true
  
  scope :active, -> { where(is_active: true) }
  
  def field_names
    metadata_fields.pluck(:name)
  end
end