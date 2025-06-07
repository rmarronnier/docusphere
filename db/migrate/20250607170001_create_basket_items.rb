class CreateBasketItems < ActiveRecord::Migration[7.1]
  def change
    create_table :basket_items do |t|
      t.references :basket, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.integer :position
      t.text :notes

      t.timestamps
    end

    add_index :basket_items, [:basket_id, :document_id], unique: true
  end
end