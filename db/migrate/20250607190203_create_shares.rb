class CreateShares < ActiveRecord::Migration[7.1]
  def change
    create_table :shares do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :permission
      t.datetime :expires_at
      t.references :shared_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
