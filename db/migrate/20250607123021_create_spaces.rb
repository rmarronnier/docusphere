class CreateSpaces < ActiveRecord::Migration[7.1]
  def change
    create_table :spaces do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
