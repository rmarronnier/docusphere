class CreateMetadata < ActiveRecord::Migration[7.1]
  def change
    create_table :metadata do |t|
      # Polymorphic association
      t.references :metadatable, polymorphic: true, null: false
      
      # Flexible metadata (key-value)
      t.string :key
      t.text :value
      
      # Structured metadata (optional link to metadata_field)
      t.references :metadata_field, foreign_key: true, null: true
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :metadata, [:metadatable_type, :metadatable_id, :key], 
              unique: true, 
              where: "metadata_field_id IS NULL",
              name: 'idx_metadata_unique_key'
              
    add_index :metadata, [:metadatable_type, :metadatable_id, :metadata_field_id], 
              unique: true, 
              where: "metadata_field_id IS NOT NULL",
              name: 'idx_metadata_unique_field'
  end
end
