class CreateImmoPromoModule < ActiveRecord::Migration[7.1]
  def change
    # Create projects table
    create_table :immo_promo_projects do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.references :project_manager, foreign_key: { to_table: :users }
      t.string :reference_number
      t.string :project_type
      t.string :status, default: "planning"
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.decimal :total_area
      t.decimal :land_area
      t.decimal :buildable_surface_area
      t.integer :total_units
      t.date :start_date
      t.date :expected_completion_date
      t.date :actual_end_date
      t.string :building_permit_number
      t.integer :total_budget_cents
      t.integer :current_budget_cents
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :immo_promo_projects, :reference_number, unique: true
    add_index :immo_promo_projects, :project_type
    add_index :immo_promo_projects, :status
    add_index :immo_promo_projects, [ :organization_id, :slug ], unique: true

    # Create phases table
    create_table :immo_promo_phases do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :responsible_user, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.string :phase_type, default: "studies"
      t.integer :position
      t.string :status, default: "pending"
      t.date :start_date
      t.date :end_date
      t.integer :budget_cents
      t.integer :actual_cost_cents
      t.decimal :progress_percentage, default: 0.0
      t.boolean :is_critical, default: false
      t.jsonb :deliverables, default: {}
      t.timestamps
    end

    add_index :immo_promo_phases, [ :project_id, :position ], unique: true
    add_index :immo_promo_phases, :status
    add_index :immo_promo_phases, :phase_type

    # Create phase_dependencies table
    create_table :immo_promo_phase_dependencies do |t|
      t.references :dependent_phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      t.references :prerequisite_phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      t.string :dependency_type, default: "finish_to_start"
      t.integer :lag_days, default: 0
      t.timestamps
    end

    add_index :immo_promo_phase_dependencies, [ :dependent_phase_id, :prerequisite_phase_id ], unique: true, name: 'idx_phase_dependencies_unique'

    # Create stakeholders table (must be before tasks as tasks references stakeholders)
    create_table :immo_promo_stakeholders do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.string :name, null: false
      t.string :stakeholder_type
      t.string :contact_person
      t.string :email
      t.string :phone
      t.text :address
      t.text :notes
      t.string :specialization
      t.boolean :is_active, default: true
      t.string :role
      t.string :company_name
      t.string :siret
      t.boolean :is_primary, default: false
      t.timestamps
    end

    add_index :immo_promo_stakeholders, :role
    # add_index :immo_promo_stakeholders, :stakeholder_type

    # Create tasks table
    create_table :immo_promo_tasks do |t|
      t.references :phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :stakeholder, foreign_key: { to_table: :immo_promo_stakeholders }
      t.string :name, null: false
      t.text :description
      t.string :task_type, default: "technical"
      t.string :status, default: "pending"
      t.string :priority, default: "medium"
      t.date :start_date
      t.date :end_date
      t.date :completed_date
      t.decimal :estimated_hours
      t.decimal :actual_hours
      t.integer :estimated_cost_cents
      t.integer :actual_cost_cents
      t.decimal :progress_percentage, default: 0.0
      t.jsonb :checklist, default: {}
      t.timestamps
    end

    add_index :immo_promo_tasks, :status
    add_index :immo_promo_tasks, :priority
    add_index :immo_promo_tasks, :end_date
    add_index :immo_promo_tasks, :task_type

    # Create task_dependencies table
    create_table :immo_promo_task_dependencies do |t|
      t.references :dependent_task, null: false, foreign_key: { to_table: :immo_promo_tasks }
      t.references :prerequisite_task, null: false, foreign_key: { to_table: :immo_promo_tasks }
      t.string :dependency_type, default: "finish_to_start"
      t.integer :lag_days, default: 0
      t.timestamps
    end

    add_index :immo_promo_task_dependencies, [ :dependent_task_id, :prerequisite_task_id ], unique: true, name: 'idx_task_dependencies_unique'

    # Create lots table
    create_table :immo_promo_lots do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.string :lot_number, null: false
      t.string :lot_type
      t.integer :floor
      t.string :building
      t.decimal :surface_area
      t.integer :rooms_count
      t.integer :price_cents
      t.string :status, default: "available"
      t.string :orientation
      t.jsonb :features, default: {}
      t.timestamps
    end

    add_index :immo_promo_lots, [ :project_id, :lot_number ], unique: true
    add_index :immo_promo_lots, :lot_type
    add_index :immo_promo_lots, :status

    # Create lot_specifications table
    create_table :immo_promo_lot_specifications do |t|
      t.references :lot, null: false, foreign_key: { to_table: :immo_promo_lots }
      t.integer :rooms
      t.integer :bedrooms
      t.integer :bathrooms
      t.boolean :has_balcony, default: false
      t.boolean :has_terrace, default: false
      t.boolean :has_parking, default: false
      t.boolean :has_storage, default: false
      t.string :energy_class
      t.boolean :accessibility_features, default: false
      t.timestamps
    end

    # Indexes removed as fields changed

    # Create reservations table
    create_table :immo_promo_reservations do |t|
      t.references :lot, null: false, foreign_key: { to_table: :immo_promo_lots }
      t.string :client_name, null: false
      t.string :client_email
      t.string :client_phone
      t.date :reservation_date
      t.date :expiry_date
      t.integer :deposit_amount_cents
      t.string :status, default: "active"
      t.text :notes
      t.timestamps
    end

    add_index :immo_promo_reservations, :status
    add_index :immo_promo_reservations, :reservation_date

    # Create budgets table
    create_table :immo_promo_budgets do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.string :name, null: false
      t.integer :fiscal_year
      t.integer :total_amount_cents
      t.string :status, default: "draft"
      t.date :approved_date
      t.references :approved_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :immo_promo_budgets, :status

    # Create budget_lines table
    create_table :immo_promo_budget_lines do |t|
      t.references :budget, null: false, foreign_key: { to_table: :immo_promo_budgets }
      t.string :category
      t.string :subcategory
      t.string :description
      t.integer :planned_amount_cents
      t.integer :actual_amount_cents
      t.integer :committed_amount_cents
      t.text :notes
      t.timestamps
    end

    add_index :immo_promo_budget_lines, :category
    add_index :immo_promo_budget_lines, :subcategory

    # Create permits table
    create_table :immo_promo_permits do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.string :permit_type, null: false
      t.string :permit_number
      t.string :status, default: "pending"
      t.date :application_date
      t.date :submitted_date
      t.date :approval_date
      t.date :approved_date
      t.date :expiry_date
      t.string :issuing_authority
      t.text :conditions
      t.text :notes
      t.jsonb :documents, default: {}
      t.timestamps
    end

    add_index :immo_promo_permits, :permit_type
    add_index :immo_promo_permits, :status
    add_index :immo_promo_permits, :permit_number

    # Create permit_conditions table
    create_table :immo_promo_permit_conditions do |t|
      t.references :permit, null: false, foreign_key: { to_table: :immo_promo_permits }
      t.text :description
      t.string :compliance_status, default: "pending"
      t.date :due_date
      t.date :compliance_date
      t.text :compliance_notes
      t.timestamps
    end

    # Index removed - field does not exist in this version

    # Create contracts table
    create_table :immo_promo_contracts do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :stakeholder, foreign_key: { to_table: :immo_promo_stakeholders }
      t.string :contract_type
      t.string :contract_number
      t.string :status, default: "draft"
      t.date :start_date
      t.date :end_date
      t.integer :amount_cents
      t.string :currency, default: "EUR"
      t.string :payment_terms
      t.text :description
      t.date :signed_date
      t.timestamps
    end

    add_index :immo_promo_contracts, :contract_type
    add_index :immo_promo_contracts, :status
    add_index :immo_promo_contracts, :contract_number

    # Create milestones table
    create_table :immo_promo_milestones do |t|
      t.references :phase, null: false, foreign_key: { to_table: :immo_promo_phases }
      t.string :name, null: false
      t.text :description
      t.date :target_date
      t.date :actual_date
      t.string :status, default: "pending"
      t.boolean :is_critical, default: false
      t.timestamps
    end

    add_index :immo_promo_milestones, :status
    add_index :immo_promo_milestones, :target_date

    # Create risks table
    create_table :immo_promo_risks do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :probability
      t.string :impact
      t.integer :risk_score
      t.string :status, default: "active"
      t.text :mitigation_plan
      t.references :owner, foreign_key: { to_table: :users }
      t.date :identified_date
      t.date :target_resolution_date
      t.timestamps
    end

    add_index :immo_promo_risks, :category
    add_index :immo_promo_risks, :status
    add_index :immo_promo_risks, :risk_score

    # Create progress_reports table
    create_table :immo_promo_progress_reports do |t|
      t.references :project, null: false, foreign_key: { to_table: :immo_promo_projects }
      t.references :prepared_by, null: false, foreign_key: { to_table: :users }
      t.date :report_date
      t.date :period_start
      t.date :period_end
      t.decimal :overall_progress
      t.decimal :budget_consumed
      t.text :key_achievements
      t.text :issues_risks
      t.text :next_period_goals
      t.timestamps
    end

    add_index :immo_promo_progress_reports, :report_date

    # Create time_logs table
    create_table :immo_promo_time_logs do |t|
      t.references :task, null: false, foreign_key: { to_table: :immo_promo_tasks }
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.decimal :hours, precision: 5, scale: 2
      t.text :description
      t.timestamps
    end

    add_index :immo_promo_time_logs, :date

    # Create certifications table
    create_table :immo_promo_certifications do |t|
      t.references :stakeholder, null: false, foreign_key: { to_table: :immo_promo_stakeholders }
      t.string :name
      t.string :issuing_body
      t.date :issue_date
      t.date :expiry_date
      t.boolean :is_verified, default: false
      t.timestamps
    end

    # Indexes for certifications adjusted
  end
end
