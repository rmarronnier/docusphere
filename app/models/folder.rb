class Folder < ApplicationRecord
  include Treeable
  include Authorizable
  include Linkable
  
  # Folders don't have direct ownership - managed through space authorizations
  owned_by :none
  
  belongs_to :space
  has_many :documents, dependent: :destroy
  has_many :metadata, class_name: 'Metadatum', as: :metadatable, dependent: :destroy
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: [:space_id, :parent_id] }
  validates :slug, presence: true, uniqueness: { scope: :space_id }
  
  before_validation :generate_slug_if_blank
  
  scope :in_space, ->(space) { where(space: space) }
  
  def full_path
    path.map(&:name).join('/')
  end
  
  def parent_folders
    ancestors
  end
  
  private
  
  def generate_slug_if_blank
    self.slug = name.parameterize if slug.blank? && name.present?
  end
end