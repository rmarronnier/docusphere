class AddAiFieldsToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :extracted_text, :text
    add_column :documents, :ai_category, :string
    add_column :documents, :ai_confidence, :decimal
    add_column :documents, :ai_summary, :text
    add_column :documents, :ai_entities, :json
    add_column :documents, :ai_classification_data, :json
    add_column :documents, :ai_processed_at, :datetime
  end
end
