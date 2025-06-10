class SearchQuery < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  
  scope :recent, -> { where(created_at: 30.days.ago..) }
  scope :most_used, -> { order(usage_count: :desc) }
  scope :favorites, -> { where(is_favorite: true) }
  
  def increment_usage!
    increment!(:usage_count)
    touch(:last_used_at)
  end
end