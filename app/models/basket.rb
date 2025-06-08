class Basket < ApplicationRecord
  belongs_to :user
  
  has_many :basket_items, dependent: :destroy
  # Basket items are polymorphic - they can contain any type of item
  
  validates :name, presence: true
  
  scope :shared, -> { where(is_shared: true) }
  scope :active, -> { where('share_expires_at IS NULL OR share_expires_at > ?', Time.current) }
  
  def add_document(document)
    basket_items.find_or_create_by(item: document) do |item|
      item.position = basket_items.maximum(:position).to_i + 1
    end
  end
  
  def remove_document(document)
    basket_items.where(item: document).destroy_all
  end
  
  def document_count
    basket_items.count
  end
  
  def empty?
    basket_items.empty?
  end
  
  def generate_share_token!
    update!(
      share_token: SecureRandom.hex(16),
      share_expires_at: 7.days.from_now,
      is_shared: true
    )
  end
end