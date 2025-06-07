class CreateProjectWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :project_workflow_steps do |t|
      t.references :workflowable, polymorphic: true, null: false
      t.string :name
      t.text :description
      t.integer :position
      t.string :status
      t.references :assigned_to, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
