class BasketItem < ApplicationRecord
  belongs_to :basket
  belongs_to :document
  
  validates :document_id, uniqueness: { scope: :basket_id }
end