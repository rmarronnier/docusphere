class AddMissingFieldsToWorkflowSubmissions < ActiveRecord::Migration[7.1]
  def change
    # Add missing columns
    add_column :workflow_submissions, :priority, :string, default: 'normal'
    add_column :workflow_submissions, :submittable_type, :string
    add_column :workflow_submissions, :submittable_id, :bigint
    add_column :workflow_submissions, :due_date, :datetime
    add_column :workflow_submissions, :submitted_at, :datetime
    add_column :workflow_submissions, :decision, :string
    add_column :workflow_submissions, :decided_at, :datetime
    add_column :workflow_submissions, :decided_by_id, :bigint
    
    # Add indexes
    add_index :workflow_submissions, [:submittable_type, :submittable_id], name: 'index_workflow_submissions_on_submittable'
    add_index :workflow_submissions, :priority
    add_index :workflow_submissions, :due_date
    
    # Add foreign key
    add_foreign_key :workflow_submissions, :users, column: :decided_by_id
  end
end