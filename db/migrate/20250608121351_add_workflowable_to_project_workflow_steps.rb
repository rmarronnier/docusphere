class AddWorkflowableToProjectWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    add_reference :project_workflow_steps, :workflowable, polymorphic: true, null: true
  end
end
