class ConsolidateGroupsIntoUserGroups < ActiveRecord::Migration[7.1]
  def up
    # Add any missing columns from groups to user_groups
    add_column :user_groups, :group_type, :string unless column_exists?(:user_groups, :group_type)
    add_column :user_groups, :is_active, :boolean, default: true unless column_exists?(:user_groups, :is_active)
    
    # Add indexes
    add_index :user_groups, :group_type unless index_exists?(:user_groups, :group_type)
    add_index :user_groups, :is_active unless index_exists?(:user_groups, :is_active)
    
    # Drop the groups table if it exists
    drop_table :groups if table_exists?(:groups)
  end
  
  def down
    # Recreate groups table
    create_table :groups do |t|
      t.string :name, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.string :group_type
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :groups, :group_type
    add_index :groups, :is_active
    
    # Remove added columns from user_groups
    remove_column :user_groups, :group_type if column_exists?(:user_groups, :group_type)
    remove_column :user_groups, :is_active if column_exists?(:user_groups, :is_active)
  end
end