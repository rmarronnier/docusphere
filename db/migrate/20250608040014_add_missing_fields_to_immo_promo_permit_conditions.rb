class AddMissingFieldsToImmoPromoPermitConditions < ActiveRecord::Migration[7.1]
  def change
    add_column :immo_promo_permit_conditions, :condition_type, :string unless column_exists?(:immo_promo_permit_conditions, :condition_type)
    add_column :immo_promo_permit_conditions, :is_fulfilled, :boolean, default: false unless column_exists?(:immo_promo_permit_conditions, :is_fulfilled)
  end
end