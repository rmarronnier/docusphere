class CreateWorkflowSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_submissions do |t|
      t.references :workflow, null: false, foreign_key: true
      t.references :submittable, polymorphic: true, null: false
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }
      t.references :current_step, foreign_key: { to_table: :workflow_steps }
      
      t.string :status, default: 'pending'
      t.integer :position
      t.string :priority, default: 'normal'
      
      # Tracking fields
      t.datetime :submitted_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :due_date
      
      # Decision tracking
      t.string :decision # approved, rejected, returned_for_revision
      t.text :decision_comment
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at
      
      # Additional metadata
      t.json :metadata # For storing custom data
      t.text :notes
      
      t.timestamps
    end
    
    add_index :workflow_submissions, [:workflow_id, :submittable_type, :submittable_id], 
              unique: true, name: 'index_workflow_submissions_on_workflow_and_submittable'
    add_index :workflow_submissions, :status
    add_index :workflow_submissions, :priority
    add_index :workflow_submissions, :due_date
    add_index :workflow_submissions, [:workflow_id, :position]
  end
end