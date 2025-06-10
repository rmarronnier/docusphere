class DashboardWidget < ApplicationRecord
  belongs_to :user_profile
  
  # Validations
  validates :widget_type, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :width, numericality: { greater_than: 0 }
  validates :height, numericality: { greater_than: 0 }
  
  # Scopes
  scope :visible, -> { where(visible: true) }
  
  # Default ordering is handled by the association in UserProfile
  # has_many :dashboard_widgets, -> { order(:position) }
end