class AddMissingColumnsToModels < ActiveRecord::Migration[7.1]
  def change
    # Add missing columns to documents table
    unless column_exists?(:documents, :current_version_number)
      add_column :documents, :current_version_number, :integer
    end
    
    unless column_exists?(:documents, :virus_scan_result)
      add_column :documents, :virus_scan_result, :text
    end
    
    unless column_exists?(:documents, :ai_processing_started_at)
      add_column :documents, :ai_processing_started_at, :datetime
    end
    
    unless column_exists?(:documents, :extracted_text)
      add_column :documents, :extracted_text, :text
    end
    
    # Add missing columns to immo_promo_phases
    unless column_exists?(:immo_promo_phases, :task_completion_percentage)
      add_column :immo_promo_phases, :task_completion_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    end
    
    # Add missing indexes
    unless index_exists?(:documents, :current_version_number)
      add_index :documents, :current_version_number
    end
    
    unless index_exists?(:documents, :ai_processing_started_at)
      add_index :documents, :ai_processing_started_at
    end
  end
end