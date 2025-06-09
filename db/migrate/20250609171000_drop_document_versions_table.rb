class DropDocumentVersionsTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :document_versions
  end
  
  def down
    create_table :document_versions do |t|
      t.bigint :document_id, null: false
      t.integer :version_number, null: false
      t.bigint :uploaded_by_id, null: false
      t.text :changes_description
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :document_versions, :document_id
    add_index :document_versions, :uploaded_by_id
    add_index :document_versions, [:document_id, :version_number], unique: true
    
    add_foreign_key :document_versions, :documents
    add_foreign_key :document_versions, :users, column: :uploaded_by_id
  end
end