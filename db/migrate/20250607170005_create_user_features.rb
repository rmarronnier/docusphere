class CreateUserFeatures < ActiveRecord::Migration[7.1]
  def change
    # Notifications
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.string :title
      t.text :message
      t.boolean :is_read, default: false
      t.json :data
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.timestamps
    end

    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :is_read
    add_index :notifications, :notification_type

    # Search queries for search history
    create_table :search_queries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :query, null: false
      t.string :search_type
      t.json :filters
      t.integer :results_count, default: 0
      t.timestamps
    end

    add_index :search_queries, :query
    add_index :search_queries, :search_type

    # Groups (different from user_groups which already exists)
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
  end
end