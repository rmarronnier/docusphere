class Tag < ApplicationRecord
  belongs_to :organization
  has_many :document_tags, dependent: :destroy
  has_many :documents, through: :document_tags
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
  
  before_save :normalize_name
  
  private
  
  def normalize_name
    self.name = name.downcase.strip
  end
end