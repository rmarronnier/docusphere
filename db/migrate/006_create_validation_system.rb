class CreateValidationSystem < ActiveRecord::Migration[7.1]
  def change
    # Create validation_templates table
    create_table :validation_templates do |t|
      t.string :name, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.string :applicable_to
      t.integer :min_validators, default: 1
      t.jsonb :validation_rules, default: {}
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :validation_templates, :applicable_to
    add_index :validation_templates, :is_active
    add_index :validation_templates, [:organization_id, :name], unique: true
    
    # Create validation_requests table
    create_table :validation_requests do |t|
      t.references :document, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :validation_template, foreign_key: true
      t.integer :min_validations, default: 1
      t.string :status, default: "pending"
      t.text :description
      t.datetime :due_date
      t.datetime :completed_at
      t.timestamps
    end
    
    add_index :validation_requests, :status
    add_index :validation_requests, :due_date
    add_index :validation_requests, :completed_at
    
    # Create document_validations table
    create_table :document_validations do |t|
      t.references :validation_request, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.references :validator, null: false, foreign_key: { to_table: :users }
      t.string :status, default: "pending"
      t.text :comment
      t.datetime :validated_at
      t.jsonb :validation_data, default: {}
      t.timestamps
    end
    
    add_index :document_validations, :status
    add_index :document_validations, :validated_at
    add_index :document_validations, [:validation_request_id, :validator_id], unique: true, name: 'idx_unique_validator_per_request'
  end
end