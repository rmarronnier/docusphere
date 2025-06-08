class CreateMetadataSystem < ActiveRecord::Migration[7.1]
  def change
    # Create metadata_templates table
    create_table :metadata_templates do |t|
      t.string :name, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.string :applicable_to
      t.jsonb :structure, default: {}
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :metadata_templates, :applicable_to
    add_index :metadata_templates, :is_active
    add_index :metadata_templates, [:organization_id, :name], unique: true
    
    # Create metadata_fields table
    create_table :metadata_fields do |t|
      t.references :metadata_template, null: false, foreign_key: true
      t.string :name, null: false
      t.string :field_type, null: false
      t.string :label
      t.text :description
      t.boolean :required, default: false
      t.jsonb :options, default: {}
      t.jsonb :validation_rules, default: {}
      t.integer :position
      t.string :default_value
      t.boolean :is_searchable, default: false
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :metadata_fields, :field_type
    add_index :metadata_fields, :position
    add_index :metadata_fields, :is_searchable
    add_index :metadata_fields, :is_active
    add_index :metadata_fields, [:metadata_template_id, :name], unique: true
    
    # Create document_metadata table (structured metadata for documents)
    create_table :document_metadata do |t|
      t.references :document, null: false, foreign_key: true
      t.references :metadata_template, null: false, foreign_key: true
      t.jsonb :values, default: {}
      t.timestamps
    end
    
    add_index :document_metadata, [:document_id, :metadata_template_id], unique: true
    
    # Create metadata table (polymorphic flexible metadata)
    create_table :metadata do |t|
      t.references :metadatable, polymorphic: true, null: false
      t.string :key
      t.text :value
      t.references :metadata_field, foreign_key: true, null: true
      t.timestamps
    end
    
    add_index :metadata, [:metadatable_type, :metadatable_id, :key], 
              unique: true, 
              where: "metadata_field_id IS NULL",
              name: 'idx_metadata_unique_key'
              
    add_index :metadata, [:metadatable_type, :metadatable_id, :metadata_field_id], 
              unique: true, 
              where: "metadata_field_id IS NOT NULL",
              name: 'idx_metadata_unique_field'
    
    # Create metadatum table (legacy compatibility)
    create_table :metadatum do |t|
      t.references :document, null: false, foreign_key: true
      t.string :key, null: false
      t.text :value
      t.timestamps
    end
    
    add_index :metadatum, [:document_id, :key], unique: true
    
    # Create search_queries table
    create_table :search_queries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.jsonb :query_params, default: {}
      t.integer :usage_count, default: 0
      t.datetime :last_used_at
      t.boolean :is_favorite, default: false
      t.timestamps
    end
    
    add_index :search_queries, :usage_count
    add_index :search_queries, :last_used_at
    add_index :search_queries, :is_favorite
  end
end