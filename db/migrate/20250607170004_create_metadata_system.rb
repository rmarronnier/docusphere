class CreateMetadataSystem < ActiveRecord::Migration[7.1]
  def change
    # Create metadata templates first
    create_table :metadata_templates do |t|
      t.string :name, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.timestamps
    end

    # Then metadata fields
    create_table :metadata_fields do |t|
      t.string :name, null: false
      t.string :field_type, null: false
      t.boolean :is_required, default: false
      t.json :options
      t.references :metadata_template, null: false, foreign_key: true
      t.timestamps
    end

    # Finally document metadata
    create_table :document_metadata do |t|
      t.references :document, null: false, foreign_key: true
      t.references :metadata_field, null: false, foreign_key: true
      t.text :value
      t.timestamps
    end

    add_index :document_metadata, [:document_id, :metadata_field_id], unique: true, name: 'idx_doc_metadata_unique'
  end
end