class Group < ApplicationRecord
  belongs_to :organization
  has_many :user_groups, dependent: :destroy
  has_many :users, through: :user_groups
  has_many :group_permissions, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :organization_id }
end