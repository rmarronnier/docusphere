class Share < ApplicationRecord
  belongs_to :document
  belongs_to :user
  belongs_to :shared_by, class_name: 'User'
  
  validates :permission, inclusion: { in: %w[read write admin] }
  
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
end
