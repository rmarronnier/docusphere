class AddMissingFieldsToImmoPromo < ActiveRecord::Migration[7.1]
  def change
    # Add missing fields to permits
    add_column :immo_promo_permits, :submitted_by_id, :bigint
    add_column :immo_promo_permits, :approved_by_id, :bigint
    add_column :immo_promo_permits, :title, :string
    add_column :immo_promo_permits, :reference, :string
    add_column :immo_promo_permits, :fee_amount_cents, :integer
    add_column :immo_promo_permits, :description, :text
    
    add_index :immo_promo_permits, :submitted_by_id
    add_index :immo_promo_permits, :approved_by_id
    
    # Add missing fields to phases
    add_column :immo_promo_phases, :actual_start_date, :date
    add_column :immo_promo_phases, :actual_end_date, :date
    
    # Add missing fields to tasks
    add_column :immo_promo_tasks, :actual_start_date, :date
    add_column :immo_promo_tasks, :actual_end_date, :date
    add_column :immo_promo_tasks, :completed_at, :datetime
    
    # Add missing fields to permit conditions
    add_column :immo_promo_permit_conditions, :met_date, :date
    
    # Add missing fields to time logs
    rename_column :immo_promo_time_logs, :log_date, :logged_date if column_exists?(:immo_promo_time_logs, :log_date)
    
    # Add foreign key constraints
    add_foreign_key :immo_promo_permits, :users, column: :submitted_by_id
    add_foreign_key :immo_promo_permits, :users, column: :approved_by_id
  end
end