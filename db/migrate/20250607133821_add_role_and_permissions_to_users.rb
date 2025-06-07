class AddRoleAndPermissionsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :permissions, :text unless column_exists?(:users, :permissions)
    # La colonne role existe déjà
  end
end
