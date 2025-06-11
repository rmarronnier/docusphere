class AddHourlyRateCentsToImmoPromoTimeLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :immo_promo_time_logs, :hourly_rate_cents, :integer
  end
end
