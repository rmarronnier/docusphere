class ProjectWorkflowTransition < ApplicationRecord
  belongs_to :workflowable, polymorphic: true
  belongs_to :user
end
