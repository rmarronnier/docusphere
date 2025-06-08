class CreateValidationRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :validation_requests do |t|
      t.references :document, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.integer :min_validations
      t.string :status
      t.datetime :completed_at

      t.timestamps
    end
  end
end
