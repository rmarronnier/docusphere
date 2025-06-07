class DocumentVersion < ApplicationRecord
  belongs_to :document
  belongs_to :created_by, class_name: 'User'
  
  has_one_attached :file
  
  validates :version_number, presence: true
  validates :file, presence: true
  
  before_validation :set_version_number, on: :create
  
  private
  
  def set_version_number
    self.version_number = (document.document_versions.maximum(:version_number) || 0) + 1
  end
end