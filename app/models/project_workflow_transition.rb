class ProjectWorkflowTransition < ApplicationRecord
  belongs_to :workflowable, polymorphic: true, optional: true
  belongs_to :project, class_name: 'Immo::Promo::Project', optional: true
  belongs_to :from_step, class_name: 'ProjectWorkflowStep', optional: true
  belongs_to :to_step, class_name: 'ProjectWorkflowStep'
  belongs_to :transitioned_by, class_name: 'User'
  belongs_to :user, optional: true
end
