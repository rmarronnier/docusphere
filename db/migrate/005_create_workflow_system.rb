class CreateWorkflowSystem < ActiveRecord::Migration[7.1]
  def change
    # Create workflows table
    create_table :workflows do |t|
      t.string :name, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.string :workflow_type
      t.jsonb :settings, default: {}
      t.string :status, default: "active"
      t.boolean :is_template, default: false
      t.timestamps
    end
    
    add_index :workflows, :workflow_type
    add_index :workflows, :status
    add_index :workflows, :is_template
    add_index :workflows, [:organization_id, :name], unique: true
    
    # Create workflow_steps table
    create_table :workflow_steps do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false
      t.string :step_type
      t.jsonb :settings, default: {}
      t.string :status, default: "pending"
      
      # Fields for advanced workflow features
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :assigned_to_group, foreign_key: { to_table: :user_groups }
      t.datetime :due_date
      t.string :priority
      t.jsonb :validation_rules, default: {}
      t.boolean :requires_approval, default: false
      t.integer :approval_count, default: 1
      t.datetime :completed_at
      
      t.timestamps
    end
    
    add_index :workflow_steps, [:workflow_id, :position], unique: true
    add_index :workflow_steps, :step_type
    add_index :workflow_steps, :status
    add_index :workflow_steps, :priority
    
    # Create workflow_submissions table
    create_table :workflow_submissions do |t|
      t.references :workflow, null: false, foreign_key: true
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }
      t.references :current_step, foreign_key: { to_table: :workflow_steps }
      t.string :status, default: "pending"
      t.jsonb :data, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.text :completion_notes
      t.timestamps
    end
    
    add_index :workflow_submissions, :status
    add_index :workflow_submissions, :started_at
    add_index :workflow_submissions, :completed_at
    
    # Create project_workflow_steps table (legacy compatibility)
    create_table :project_workflow_steps do |t|
      t.string :name, null: false
      t.text :description
      t.integer :sequence_number, null: false
      t.boolean :requires_approval, default: false
      t.boolean :is_active, default: true
      t.references :organization, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :project_workflow_steps, [:organization_id, :sequence_number], unique: true
    add_index :project_workflow_steps, :is_active
    
    # Create project_workflow_transitions table (legacy compatibility)
    create_table :project_workflow_transitions do |t|
      t.references :project, null: false, foreign_key: { to_table: :organizations }
      t.references :from_step, foreign_key: { to_table: :project_workflow_steps }
      t.references :to_step, null: false, foreign_key: { to_table: :project_workflow_steps }
      t.references :transitioned_by, null: false, foreign_key: { to_table: :users }
      t.text :notes
      t.datetime :transitioned_at, null: false
      t.timestamps
    end
    
    add_index :project_workflow_transitions, :transitioned_at
  end
end