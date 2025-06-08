class BasketItem < ApplicationRecord
  belongs_to :basket
  belongs_to :item, polymorphic: true
  
  validates :item_id, uniqueness: { scope: [:basket_id, :item_type] }
  validates :position, presence: true
  
  # Helper methods for common item types
  def document
    item if item_type == 'Document'
  end
  
  def document?
    item_type == 'Document'
  end
end