class Link < ApplicationRecord
  belongs_to :document
  belongs_to :linked_document, class_name: 'Document'
  
  validates :link_type, inclusion: { in: %w[reference related parent child version] }
end
