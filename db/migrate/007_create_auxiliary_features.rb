class CreateAuxiliaryFeatures < ActiveRecord::Migration[7.1]
  def change
    # Create baskets table
    create_table :baskets do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.string :basket_type, default: "personal"
      t.boolean :is_shared, default: false
      t.jsonb :settings, default: {}
      t.timestamps
    end
    
    add_index :baskets, :basket_type
    add_index :baskets, :is_shared
    
    # Create basket_items table
    create_table :basket_items do |t|
      t.references :basket, null: false, foreign_key: true
      t.references :item, polymorphic: true, null: false
      t.integer :position
      t.text :notes
      t.timestamps
    end
    
    add_index :basket_items, [:item_type, :item_id]
    add_index :basket_items, :position
    add_index :basket_items, [:basket_id, :item_type, :item_id], unique: true
    
    # Create links table
    create_table :links do |t|
      t.references :source, polymorphic: true, null: false
      t.references :target, polymorphic: true, null: false
      t.string :link_type
      t.text :description
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :links, [:source_type, :source_id]
    add_index :links, [:target_type, :target_id]
    add_index :links, :link_type
    
    # Create user_features table (feature flags per user)
    create_table :user_features do |t|
      t.references :user, null: false, foreign_key: true
      t.string :feature_key, null: false
      t.boolean :enabled, default: false
      t.jsonb :settings, default: {}
      t.datetime :enabled_at
      t.timestamps
    end
    
    add_index :user_features, [:user_id, :feature_key], unique: true
    add_index :user_features, :feature_key
    add_index :user_features, :enabled
  end
end