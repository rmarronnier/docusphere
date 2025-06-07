class CreateBaskets < ActiveRecord::Migration[7.1]
  def change
    create_table :baskets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :is_shared, default: false
      t.string :share_token
      t.datetime :share_expires_at

      t.timestamps
    end

    add_index :baskets, :share_token, unique: true
  end
end