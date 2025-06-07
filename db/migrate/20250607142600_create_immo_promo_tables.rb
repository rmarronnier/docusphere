class CreateImmoPromoTables < ActiveRecord::Migration[7.1]
  def change
    # Projects table
    create_table :immo_promo_projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project_manager, null: true, foreign_key: { to_table: :users }
      
      t.string :name, null: false
      t.string :reference, null: false
      t.text :description
      t.string :project_type, null: false
      t.string :status, default: 'planning'
      
      # Addressable fields
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      
      # Schedulable fields
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :actual_start_date
      t.datetime :actual_end_date
      
      # Budget fields (in cents)
      t.integer :total_budget_cents
      t.integer :current_budget_cents
      t.string :currency, default: 'EUR'
      
      # Additional project fields
      t.integer :total_units
      t.decimal :total_surface_area, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end
    
    # Phases table
    create_table :immo_promo_phases do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :responsible_user, null: true, foreign_key: { to_table: :users }
      
      t.string :name, null: false
      t.text :description
      t.string :phase_type, null: false
      t.string :status, default: 'pending'
      t.integer :position, null: false
      t.boolean :is_critical, default: false
      
      # Schedulable fields
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :actual_start_date
      t.datetime :actual_end_date
      
      # Budget fields
      t.integer :budget_cents
      t.integer :actual_cost_cents
      t.string :currency, default: 'EUR'
      
      t.text :notes

      t.timestamps
    end
    
    # Stakeholders table
    create_table :immo_promo_stakeholders do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      
      t.string :name, null: false
      t.string :stakeholder_type, null: false
      t.string :email
      t.string :phone, null: false
      t.string :contact_person
      t.string :siret
      t.boolean :is_active, default: true
      
      # Addressable fields
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :country
      
      t.text :notes

      t.timestamps
    end
    
    # Tasks table
    create_table :immo_promo_tasks do |t|
      t.references :phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.references :stakeholder, null: true, foreign_key: { to_table: :immo_promo_stakeholders }
      
      t.string :name, null: false
      t.text :description
      t.string :task_type, null: false
      t.string :status, default: 'pending'
      t.string :priority, default: 'medium'
      
      # Schedulable fields
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :actual_start_date
      t.datetime :actual_end_date
      
      # Time and cost tracking
      t.decimal :estimated_hours, precision: 8, scale: 2
      t.integer :estimated_cost_cents
      t.integer :actual_cost_cents
      t.string :currency, default: 'EUR'
      
      t.text :notes

      t.timestamps
    end
    
    # Permits table
    create_table :immo_promo_permits do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      
      t.string :permit_type, null: false
      t.string :status, default: 'draft'
      t.string :reference_number, null: false
      t.string :authority, null: false
      t.text :description
      
      # Schedulable fields
      t.datetime :submission_date
      t.datetime :expected_decision_date
      t.datetime :actual_decision_date
      t.datetime :expiry_date
      
      t.text :notes

      t.timestamps
    end
    
    # Lots table
    create_table :immo_promo_lots do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      
      t.string :reference, null: false
      t.string :lot_type, null: false
      t.string :status, default: 'planned'
      t.decimal :surface_area, precision: 10, scale: 2, null: false
      t.decimal :balcony_area, precision: 10, scale: 2
      t.integer :floor_level, null: false
      t.integer :rooms_count
      
      # Pricing
      t.integer :base_price_cents
      t.integer :final_price_cents
      t.string :currency, default: 'EUR'
      
      t.text :description
      t.text :notes

      t.timestamps
    end
    
    # Budgets table
    create_table :immo_promo_budgets do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      
      t.string :name, null: false
      t.string :budget_type, null: false
      t.integer :version, null: false
      t.boolean :is_current, default: false
      
      t.integer :total_amount_cents, null: false
      t.integer :spent_amount_cents
      t.string :currency, default: 'EUR'
      
      t.text :notes

      t.timestamps
    end
    
    # Budget Lines table
    create_table :immo_promo_budget_lines do |t|
      t.references :budget, null: false, foreign_key: { to_table: :immo_promo_budgets }
      
      t.string :name, null: false
      t.string :category, null: false
      t.text :description
      
      t.integer :amount_cents, null: false
      t.integer :spent_amount_cents
      t.string :currency, default: 'EUR'

      t.timestamps
    end
    
    # Milestones table
    create_table :immo_promo_milestones do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :phase, null: true, foreign_key: { to_table: :immo_promo_phases }
      
      t.string :name, null: false
      t.text :description
      t.string :milestone_type, null: false
      t.string :status, default: 'pending'
      t.boolean :is_critical, default: false
      
      t.datetime :target_date
      t.datetime :actual_date
      t.datetime :completed_at
      
      t.text :notes

      t.timestamps
    end
    
    # Contracts table
    create_table :immo_promo_contracts do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :stakeholder, null: false, foreign_key: { to_table: :immo_promo_stakeholders }
      
      t.string :reference, null: false
      t.string :contract_type, null: false
      t.string :status, default: 'draft'
      t.text :description
      
      # Schedulable fields
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :signature_date
      
      # Financial
      t.integer :amount_cents, null: false
      t.integer :paid_amount_cents
      t.string :currency, default: 'EUR'
      
      t.text :notes

      t.timestamps
    end
    
    # Certifications table
    create_table :immo_promo_certifications do |t|
      t.references :stakeholder, null: false, foreign_key: { to_table: :immo_promo_stakeholders }
      
      t.string :certification_type, null: false
      t.string :name, null: false
      t.string :certificate_number, null: false
      t.string :issuing_authority, null: false
      t.text :description
      
      t.datetime :issue_date
      t.datetime :expiry_date
      t.boolean :is_valid, default: true

      t.timestamps
    end
    
    # Risks table
    create_table :immo_promo_risks do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :identified_by, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      
      t.string :title, null: false
      t.text :description
      t.string :risk_type, null: false
      t.string :probability, null: false
      t.string :impact, null: false
      t.string :status, default: 'identified'
      
      t.text :mitigation_plan
      t.text :contingency_plan
      
      t.datetime :identified_at
      t.datetime :reviewed_at

      t.timestamps
    end
    
    # Phase Dependencies table
    create_table :immo_promo_phase_dependencies do |t|
      t.references :prerequisite_phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      t.references :dependent_phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      
      t.string :dependency_type, default: 'finish_to_start'
      t.integer :lag_days, default: 0

      t.timestamps
    end
    
    # Task Dependencies table
    create_table :immo_promo_task_dependencies do |t|
      t.references :prerequisite_task, null: false, foreign_key: { to_table: :immo_promo_tasks }
      t.references :dependent_task, null: false, foreign_key: { to_table: :immo_promo_tasks }
      
      t.string :dependency_type, default: 'finish_to_start'
      t.integer :lag_days, default: 0

      t.timestamps
    end
    
    # Time Logs table
    create_table :immo_promo_time_logs do |t|
      t.references :task, null: false, foreign_key: { to_table: :immo_promo_tasks }
      t.references :user, null: false, foreign_key: true
      
      t.decimal :hours, precision: 8, scale: 2, null: false
      t.date :log_date, null: false
      t.text :description

      t.timestamps
    end
    
    # Progress Reports table
    create_table :immo_promo_progress_reports do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      
      t.string :report_type, null: false
      t.date :report_date, null: false
      t.decimal :overall_progress_percentage, precision: 5, scale: 2
      
      t.text :accomplishments
      t.text :issues
      t.text :delays
      t.text :next_steps
      t.text :weather_conditions

      t.timestamps
    end
    
    # Reservations table
    create_table :immo_promo_reservations do |t|
      t.references :lot, null: false, foreign_key: { to_table: :immo_promo_lots }
      t.references :client, null: false, foreign_key: { to_table: :users }
      
      t.string :status, default: 'pending'
      t.datetime :reservation_date, null: false
      t.datetime :expiry_date, null: false
      t.datetime :confirmation_date
      
      t.integer :deposit_amount_cents
      t.integer :final_price_cents, null: false
      t.string :currency, default: 'EUR'
      
      t.text :notes

      t.timestamps
    end
    
    # Permit Conditions table
    create_table :immo_promo_permit_conditions do |t|
      t.references :permit, null: false, foreign_key: { to_table: :immo_promo_permits }
      
      t.string :condition_type, null: false
      t.text :description, null: false
      t.boolean :is_fulfilled, default: false
      t.datetime :due_date
      t.datetime :fulfilled_date

      t.timestamps
    end
    
    # Lot Specifications table
    create_table :immo_promo_lot_specifications do |t|
      t.references :lot, null: false, foreign_key: { to_table: :immo_promo_lots }
      
      t.string :specification_type, null: false
      t.string :name, null: false
      t.text :description
      t.string :value
      t.boolean :is_standard, default: true

      t.timestamps
    end
    
    # Add indexes
    add_index :immo_promo_projects, [:organization_id, :reference], unique: true
    add_index :immo_promo_projects, :project_type
    add_index :immo_promo_projects, :status
    
    add_index :immo_promo_phases, [:project_id, :position], unique: true
    add_index :immo_promo_phases, :phase_type
    add_index :immo_promo_phases, :status
    
    add_index :immo_promo_tasks, :task_type
    add_index :immo_promo_tasks, :status
    add_index :immo_promo_tasks, :priority
    
    add_index :immo_promo_stakeholders, :stakeholder_type
    add_index :immo_promo_stakeholders, :is_active
    
    add_index :immo_promo_permits, [:project_id, :reference_number], unique: true
    add_index :immo_promo_permits, :permit_type
    add_index :immo_promo_permits, :status
    
    add_index :immo_promo_lots, [:project_id, :reference], unique: true
    add_index :immo_promo_lots, :lot_type
    add_index :immo_promo_lots, :status
    
    add_index :immo_promo_budgets, [:project_id, :version], unique: true
    add_index :immo_promo_budgets, :is_current
    
    add_index :immo_promo_contracts, [:project_id, :reference], unique: true
    add_index :immo_promo_contracts, :contract_type
    add_index :immo_promo_contracts, :status
    
    add_index :immo_promo_certifications, [:stakeholder_id, :certificate_number], unique: true
    add_index :immo_promo_certifications, :certification_type
    add_index :immo_promo_certifications, :is_valid
    
    add_index :immo_promo_risks, :risk_type
    add_index :immo_promo_risks, :status
    add_index :immo_promo_risks, [:probability, :impact]
    
    add_index :immo_promo_phase_dependencies, [:prerequisite_phase_id, :dependent_phase_id], unique: true, name: 'index_phase_dependencies_unique'
    add_index :immo_promo_task_dependencies, [:prerequisite_task_id, :dependent_task_id], unique: true, name: 'index_task_dependencies_unique'
    
    add_index :immo_promo_time_logs, [:task_id, :user_id, :log_date], unique: true
    add_index :immo_promo_time_logs, :log_date
    
    add_index :immo_promo_progress_reports, :report_type
    add_index :immo_promo_progress_reports, :report_date
    
    add_index :immo_promo_reservations, :status
    add_index :immo_promo_reservations, :reservation_date
    
    add_index :immo_promo_permit_conditions, :is_fulfilled
    add_index :immo_promo_permit_conditions, :condition_type
    
    add_index :immo_promo_lot_specifications, :specification_type
    add_index :immo_promo_lot_specifications, :is_standard
  end
end