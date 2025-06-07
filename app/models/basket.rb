class Basket < ApplicationRecord
  belongs_to :user
  
  has_many :basket_items, dependent: :destroy
  has_many :documents, through: :basket_items
  
  validates :name, presence: true
  
  scope :shared, -> { where(is_shared: true) }
  scope :active, -> { where('share_expires_at IS NULL OR share_expires_at > ?', Time.current) }
  
  def add_document(document)
    basket_items.find_or_create_by(document: document)
  end
  
  def remove_document(document)
    basket_items.where(document: document).destroy_all
  end
  
  def document_count
    documents.count
  end
  
  def empty?
    documents.empty?
  end
  
  def generate_share_token!
    update!(
      share_token: SecureRandom.hex(16),
      share_expires_at: 7.days.from_now,
      is_shared: true
    )
  end
end