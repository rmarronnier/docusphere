class CreateCoreSystem < ActiveRecord::Migration[7.1]
  def change
    # Create organizations table
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :settings, default: {}
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :organizations, :slug, unique: true
    add_index :organizations, :is_active
    
    # Create users table with Devise
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :first_name
      t.string :last_name
      t.references :organization, null: false, foreign_key: true
      
      # Devise fields
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at
      
      # Roles and permissions
      t.string :role, default: "user", null: false
      t.jsonb :permissions, default: {}
      
      t.timestamps
    end
    
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
    add_index :users, :role
    
    # Create notifications table
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type
      t.string :title
      t.text :message
      t.jsonb :data, default: {}
      t.datetime :read_at
      t.references :notifiable, polymorphic: true
      t.timestamps
    end
    
    add_index :notifications, :notification_type
    add_index :notifications, :read_at
    
    # Install Audited
    create_table :audits do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :associated_id, :integer
      t.column :associated_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :audited_changes, :text
      t.column :version, :integer, default: 0
      t.column :comment, :string
      t.column :remote_address, :string
      t.column :request_uuid, :string
      t.column :created_at, :datetime
    end

    add_index :audits, [:auditable_type, :auditable_id, :version], name: "auditable_index"
    add_index :audits, [:associated_type, :associated_id], name: "associated_index"
    add_index :audits, [:user_id, :user_type], name: "user_index"
    add_index :audits, :request_uuid
    add_index :audits, :created_at
    
    # Create versions table for paper_trail
    create_table :versions do |t|
      t.string   :item_type, null: false
      t.bigint   :item_id, null: false
      t.string   :event, null: false
      t.string   :whodunnit
      t.text     :object
      t.text     :object_changes
      t.datetime :created_at
    end
    
    add_index :versions, [:item_type, :item_id]
    add_index :versions, :event
    add_index :versions, :whodunnit
    add_index :versions, :created_at
  end
end