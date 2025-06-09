class Tag < ApplicationRecord
  belongs_to :organization
  has_many :document_tags, dependent: :destroy
  has_many :documents, through: :document_tags
  
  before_validation :normalize_name
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
  
  private
  
  def normalize_name
    self.name = name.downcase.strip if name.present?
  end
end