class Basket < ApplicationRecord
  belongs_to :user
  belongs_to :space
  
  has_many :basket_items, dependent: :destroy
  has_many :documents, through: :basket_items
  
  validates :name, presence: true
  validates :basket_type, inclusion: { in: %w[personal shared] }
  
  scope :personal, -> { where(basket_type: 'personal') }
  scope :shared, -> { where(basket_type: 'shared') }
end