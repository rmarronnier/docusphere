class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Devise modules will be added after devise:install
  
  belongs_to :organization
  has_many :documents, dependent: :destroy
  has_many :document_shares, dependent: :destroy
  has_many :shared_documents, through: :document_shares, source: :document
  has_many :workflows, dependent: :destroy
  has_many :workflow_steps, dependent: :destroy
  has_many :baskets, dependent: :destroy
  has_many :user_groups, dependent: :destroy
  has_many :groups, through: :user_groups
  has_many :notifications, dependent: :destroy
  has_many :search_queries, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.presence || email
  end
end