class ChangeBudgetCentsToLong < ActiveRecord::Migration[7.1]
  def up
    # Changer les colonnes budget de integer vers bigint pour supporter de plus gros montants
    change_column :immo_promo_projects, :total_budget_cents, :bigint
    change_column :immo_promo_projects, :current_budget_cents, :bigint
  end

  def down
    # Retour vers integer (attention aux données existantes)
    change_column :immo_promo_projects, :total_budget_cents, :integer
    change_column :immo_promo_projects, :current_budget_cents, :integer
  end
end