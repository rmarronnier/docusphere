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
    
    # Note: We'll use the existing polymorphic metadata table
    # instead of creating document_metadata
  end
end