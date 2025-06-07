class AddSlugToFolders < ActiveRecord::Migration[7.1]
  def change
    add_column :folders, :slug, :string
    add_index :folders, [:space_id, :slug], unique: true
  end
end
