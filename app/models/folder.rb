class Folder < ApplicationRecord
  belongs_to :space
  belongs_to :parent, class_name: 'Folder', optional: true
  has_many :children, class_name: 'Folder', foreign_key: 'parent_id', dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :folder_metadata, dependent: :destroy
  
  has_ancestry
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: [:space_id, :parent_id] }
  
  def full_path
    ancestors.map(&:name).push(name).join('/')
  end
end