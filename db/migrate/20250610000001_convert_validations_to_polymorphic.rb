class ConvertValidationsToPolymorphic < ActiveRecord::Migration[7.1]
  def change
    # Add polymorphic columns to validation_requests
    add_reference :validation_requests, :validatable, polymorphic: true, index: true
    
    # Add polymorphic columns to document_validations
    add_reference :document_validations, :validatable, polymorphic: true, index: true
    
    # Populate the new polymorphic columns with existing document data
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE validation_requests 
          SET validatable_type = 'Document', 
              validatable_id = document_id 
          WHERE document_id IS NOT NULL
        SQL
        
        execute <<-SQL
          UPDATE document_validations 
          SET validatable_type = 'Document', 
              validatable_id = document_id 
          WHERE document_id IS NOT NULL
        SQL
        
        # Make polymorphic columns NOT NULL after population
        change_column_null :validation_requests, :validatable_type, false
        change_column_null :validation_requests, :validatable_id, false
        change_column_null :document_validations, :validatable_type, false
        change_column_null :document_validations, :validatable_id, false
      end
      
      dir.down do
        # When rolling back, clear the polymorphic columns
        execute <<-SQL
          UPDATE validation_requests 
          SET validatable_type = NULL, 
              validatable_id = NULL
        SQL
        
        execute <<-SQL
          UPDATE document_validations 
          SET validatable_type = NULL, 
              validatable_id = NULL
        SQL
      end
    end
    
    # Remove foreign key constraints on document_id
    remove_foreign_key :validation_requests, :documents
    remove_foreign_key :document_validations, :documents
    
    # Remove the old document_id columns and their indexes
    remove_index :validation_requests, :document_id
    remove_index :document_validations, :document_id
    remove_column :validation_requests, :document_id, :bigint
    remove_column :document_validations, :document_id, :bigint
  end
end