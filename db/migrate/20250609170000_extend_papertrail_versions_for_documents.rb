class ExtendPapertrailVersionsForDocuments < ActiveRecord::Migration[7.1]
  def change
    # Extend the existing versions table to support document-specific features
    add_column :versions, :version_number, :integer
    add_column :versions, :comment, :text
    add_column :versions, :created_by_id, :bigint
    add_column :versions, :file_metadata, :jsonb, default: {}
    
    # Add indexes for performance
    add_index :versions, :created_by_id
    add_index :versions, [:item_type, :item_id, :version_number], name: 'index_versions_on_item_and_version_number'
    
    # Add foreign key to users
    add_foreign_key :versions, :users, column: :created_by_id
    
    # Create a sequence for version numbers per document
    execute <<-SQL
      CREATE OR REPLACE FUNCTION set_document_version_number()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.item_type = 'Document' THEN
          NEW.version_number := COALESCE(
            (SELECT MAX(version_number) + 1 
             FROM versions 
             WHERE item_type = 'Document' 
             AND item_id = NEW.item_id), 
            1
          );
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      
      CREATE TRIGGER set_version_number_before_insert
      BEFORE INSERT ON versions
      FOR EACH ROW
      EXECUTE FUNCTION set_document_version_number();
    SQL
  end
  
  def down
    # Remove trigger and function
    execute <<-SQL
      DROP TRIGGER IF EXISTS set_version_number_before_insert ON versions;
      DROP FUNCTION IF EXISTS set_document_version_number();
    SQL
    
    # Remove foreign key
    remove_foreign_key :versions, column: :created_by_id
    
    # Remove indexes
    remove_index :versions, name: 'index_versions_on_item_and_version_number'
    remove_index :versions, :created_by_id
    
    # Remove columns
    remove_column :versions, :file_metadata
    remove_column :versions, :created_by_id
    remove_column :versions, :comment
    remove_column :versions, :version_number
  end
end