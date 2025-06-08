class AddProcessingFieldsToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :processing_started_at, :datetime
    add_column :documents, :processing_completed_at, :datetime
    add_column :documents, :processing_error, :text
    add_column :documents, :processing_metadata, :jsonb, default: {}
    add_column :documents, :extracted_content, :text
    
    add_index :documents, :processing_started_at
    add_index :documents, :processing_completed_at
  end
end