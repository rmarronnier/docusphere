class CreateProjectWorkflowTransitions < ActiveRecord::Migration[7.1]
  def change
    create_table :project_workflow_transitions do |t|
      t.references :workflowable, polymorphic: true, null: false
      t.string :from_status
      t.string :to_status
      t.references :user, null: false, foreign_key: true
      t.text :comment
      t.datetime :transitioned_at

      t.timestamps
    end
  end
end
