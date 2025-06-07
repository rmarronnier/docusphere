class CreateFolders < ActiveRecord::Migration[7.1]
  def change
    create_table :folders do |t|
      t.string :name
      t.text :description
      t.references :space, null: false, foreign_key: true
      t.string :ancestry

      t.timestamps
    end
    add_index :folders, :ancestry
  end
end
