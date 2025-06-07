class AddFieldsToWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_steps, :status, :string, default: 'pending'
    add_reference :workflow_steps, :assignee, foreign_key: { to_table: :users }
    add_reference :workflow_steps, :completed_by, foreign_key: { to_table: :users }
    add_column :workflow_steps, :completed_at, :datetime
    
    add_index :workflow_steps, :status
  end
end