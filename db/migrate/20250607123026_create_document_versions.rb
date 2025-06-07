class CreateDocumentVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :document_versions do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :version_number
      t.text :comment
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
