class ProjectWorkflowStep < ApplicationRecord
  belongs_to :organization
  belongs_to :assigned_to, class_name: 'User', optional: true
  
  validates :name, presence: true
  validates :sequence_number, presence: true, uniqueness: { scope: :organization_id }
end
