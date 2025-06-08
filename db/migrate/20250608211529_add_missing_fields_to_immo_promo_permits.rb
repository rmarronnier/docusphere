class AddMissingFieldsToImmoPromoPermits < ActiveRecord::Migration[7.1]
  def change
    add_column :immo_promo_permits, :name, :string
    add_column :immo_promo_permits, :cost, :decimal, precision: 10, scale: 2
    add_column :immo_promo_permits, :expected_approval_date, :date
  end
end
