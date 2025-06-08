class Link < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true
  
  validates :link_type, inclusion: { in: %w[reference related parent child version] }
  
  scope :by_type, ->(type) { where(link_type: type) }
end
