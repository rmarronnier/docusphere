class CreateAuthorizationSystem < ActiveRecord::Migration[7.1]
  def change
    # Create user_groups table
    create_table :user_groups do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.string :group_type
      t.boolean :is_active, default: true
      t.jsonb :permissions, default: {}
      t.timestamps
    end
    
    add_index :user_groups, :group_type
    add_index :user_groups, :is_active
    add_index :user_groups, [:organization_id, :name], unique: true
    add_index :user_groups, [:organization_id, :slug], unique: true
    
    # Create user_group_memberships table
    create_table :user_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_group, null: false, foreign_key: true
      t.string :role, default: "member"
      t.datetime :joined_at
      t.timestamps
    end
    
    add_index :user_group_memberships, [:user_id, :user_group_id], unique: true
    add_index :user_group_memberships, :role
    
    # Create authorizations table
    create_table :authorizations do |t|
      t.references :authorizable, polymorphic: true, null: false
      t.references :user, foreign_key: true
      t.references :user_group, foreign_key: true
      t.string :permission_level, null: false
      t.references :granted_by, foreign_key: { to_table: :users }
      t.references :revoked_by, foreign_key: { to_table: :users }
      t.datetime :granted_at
      t.datetime :revoked_at
      t.datetime :expires_at
      t.text :comment
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :authorizations, [:authorizable_type, :authorizable_id]
    add_index :authorizations, :permission_level
    add_index :authorizations, :expires_at
    add_index :authorizations, :is_active
    
    # Add check constraint to ensure either user or user_group is present, but not both
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE authorizations
          ADD CONSTRAINT check_user_or_group_present
          CHECK (
            (user_id IS NOT NULL AND user_group_id IS NULL) OR
            (user_id IS NULL AND user_group_id IS NOT NULL)
          );
        SQL
      end
      
      dir.down do
        execute <<-SQL
          ALTER TABLE authorizations
          DROP CONSTRAINT IF EXISTS check_user_or_group_present;
        SQL
      end
    end
    
    # Create shares table (generic sharing system)
    create_table :shares do |t|
      t.references :shareable, polymorphic: true, null: false
      t.references :shared_by, null: false, foreign_key: { to_table: :users }
      t.references :shared_with, foreign_key: { to_table: :users }
      t.references :shared_with_group, foreign_key: { to_table: :user_groups }
      t.string :email
      t.string :access_level, default: "read"
      t.datetime :expires_at
      t.string :access_token
      t.boolean :is_active, default: true
      t.text :message
      t.timestamps
    end
    
    add_index :shares, [:shareable_type, :shareable_id]
    add_index :shares, :access_token, unique: true
    add_index :shares, :expires_at
    add_index :shares, :is_active
  end
end