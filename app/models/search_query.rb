class SearchQuery < ApplicationRecord
  belongs_to :user
  
  validates :query, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(search_type: type) }
end