class AddWorkflowableToProjectWorkflowTransitions < ActiveRecord::Migration[7.1]
  def change
    add_reference :project_workflow_transitions, :workflowable, polymorphic: true, null: true
  end
end
