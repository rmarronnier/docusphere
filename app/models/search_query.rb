class SearchQuery < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :most_used, -> { order(usage_count: :desc) }
  scope :favorites, -> { where(is_favorite: true) }
  
  def increment_usage!
    increment!(:usage_count)
    touch(:last_used_at)
  end
end