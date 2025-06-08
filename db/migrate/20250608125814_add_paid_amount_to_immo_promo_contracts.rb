class AddPaidAmountToImmoPromoContracts < ActiveRecord::Migration[7.1]
  def change
    add_column :immo_promo_contracts, :paid_amount_cents, :integer
  end
end
