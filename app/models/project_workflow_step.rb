class ProjectWorkflowStep < ApplicationRecord
  belongs_to :workflowable, polymorphic: true
  belongs_to :assigned_to
end
