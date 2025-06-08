class AddMissingFieldsToImmoPromoModels < ActiveRecord::Migration[7.1]
  def change
    # Add missing fields to budgets
    add_column :immo_promo_budgets, :budget_type, :string, default: 'initial' unless column_exists?(:immo_promo_budgets, :budget_type)
    add_column :immo_promo_budgets, :version, :string unless column_exists?(:immo_promo_budgets, :version)
    add_column :immo_promo_budgets, :spent_amount_cents, :integer unless column_exists?(:immo_promo_budgets, :spent_amount_cents)
    add_column :immo_promo_budgets, :is_current, :boolean, default: false unless column_exists?(:immo_promo_budgets, :is_current)
    
    # Add missing fields to contracts
    add_column :immo_promo_contracts, :terms, :text unless column_exists?(:immo_promo_contracts, :terms)
    
    # Add missing fields to milestones  
    add_column :immo_promo_milestones, :milestone_type, :string unless column_exists?(:immo_promo_milestones, :milestone_type)
    add_column :immo_promo_milestones, :completed_at, :datetime unless column_exists?(:immo_promo_milestones, :completed_at)
    
    # Add missing fields to phases
    add_column :immo_promo_phases, :deliverables_count, :integer, default: 0 unless column_exists?(:immo_promo_phases, :deliverables_count)
    
    # Add missing fields to lots
    add_column :immo_promo_lots, :price, :decimal unless column_exists?(:immo_promo_lots, :price)
    
    # Fix lot_specifications
    add_column :immo_promo_lot_specifications, :category, :string unless column_exists?(:immo_promo_lot_specifications, :category)
    
    # Fix permit_conditions 
    add_column :immo_promo_permit_conditions, :status, :string, default: 'pending' unless column_exists?(:immo_promo_permit_conditions, :status)
    add_column :immo_promo_permit_conditions, :condition_type, :string unless column_exists?(:immo_promo_permit_conditions, :condition_type)
    add_column :immo_promo_permit_conditions, :is_fulfilled, :boolean, default: false unless column_exists?(:immo_promo_permit_conditions, :is_fulfilled)
    
    # Fix time_logs - rename date to log_date
    if column_exists?(:immo_promo_time_logs, :date)
      rename_column :immo_promo_time_logs, :date, :log_date
    end
    
    # Fix certifications
    add_column :immo_promo_certifications, :certification_type, :string unless column_exists?(:immo_promo_certifications, :certification_type)
    add_column :immo_promo_certifications, :is_valid, :boolean, default: true unless column_exists?(:immo_promo_certifications, :is_valid)
  end
end