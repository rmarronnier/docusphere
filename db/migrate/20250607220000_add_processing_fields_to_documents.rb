class AddProcessingFieldsToDocuments < ActiveRecord::Migration[7.1]
  def change
    # Add processing status enum
    add_column :documents, :processing_status, :string, default: 'pending'
    add_index :documents, :processing_status
    
    # Add processing timestamps
    add_column :documents, :processing_started_at, :datetime
    add_column :documents, :processing_completed_at, :datetime
    add_column :documents, :processing_error, :text
    
    # Add OCR flag
    add_column :documents, :ocr_performed, :boolean, default: false
    
    # Add virus scan status
    add_column :documents, :virus_scan_status, :string
    add_column :documents, :virus_scan_performed_at, :datetime
    add_column :documents, :virus_scan_result, :text
    
    # Add index for finding documents to process
    add_index :documents, [:processing_status, :created_at]
  end
end