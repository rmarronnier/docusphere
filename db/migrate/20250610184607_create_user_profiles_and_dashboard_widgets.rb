class CreateUserProfilesAndDashboardWidgets < ActiveRecord::Migration[7.1]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :profile_type, null: false
      t.jsonb :preferences, default: {}
      t.jsonb :dashboard_config, default: {}
      t.jsonb :notification_settings, default: {}
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :user_profiles, :profile_type
    add_index :user_profiles, [:user_id, :active], unique: true, where: "active = true"
    
    # Table pour les préférences de widgets
    create_table :dashboard_widgets do |t|
      t.references :user_profile, null: false, foreign_key: true
      t.string :widget_type, null: false
      t.integer :position, null: false
      t.integer :width, default: 1
      t.integer :height, default: 1
      t.jsonb :config, default: {}
      t.boolean :visible, default: true
      
      t.timestamps
    end
    
    add_index :dashboard_widgets, [:user_profile_id, :position]
  end
end