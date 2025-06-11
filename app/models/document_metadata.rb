class DocumentMetadata < ApplicationRecord
  belongs_to :document
  belongs_to :metadata_template
  
  validates :document_id, uniqueness: { scope: :metadata_template_id }
  
  # JSON field to store values according to the template's fields
  serialize :values, JSON if Rails::VERSION::MAJOR < 7
end