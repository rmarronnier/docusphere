class SearchQuery < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :query, presence: true, length: { minimum: 1, maximum: 500 }
  
  scope :recent, -> { where(created_at: 30.days.ago..) }
  scope :most_used, -> { order(usage_count: :desc) }
  scope :favorites, -> { where(is_favorite: true) }
  scope :popular, -> { select('query, COUNT(*) as count').group(:query).order(Arel.sql('COUNT(*) DESC')) }
  
  def increment_usage!
    increment!(:usage_count)
    touch(:last_used_at)
  end
  
  def normalized_query
    query&.downcase&.strip
  end
end