class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.references :document, null: false, foreign_key: true
      t.references :linked_document, null: false, foreign_key: { to_table: :documents }
      t.string :link_type

      t.timestamps
    end
  end
end
