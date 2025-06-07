class CreateWorkflows < ActiveRecord::Migration[7.1]
  def change
    create_table :workflows do |t|
      t.string :name, null: false
      t.text :description
      t.string :workflow_type
      t.boolean :is_active, default: true
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.json :configuration

      t.timestamps
    end

    add_index :workflows, :workflow_type
    add_index :workflows, :is_active
  end
end