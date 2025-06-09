class AddDocumentableToDocuments < ActiveRecord::Migration[7.1]
  def change
    # Add polymorphic association for ImmoPromo integration
    add_column :documents, :documentable_type, :string
    add_column :documents, :documentable_id, :bigint
    add_index :documents, [:documentable_type, :documentable_id]
    
    # Add document category for ImmoPromo document organization
    add_column :documents, :document_category, :string
    add_index :documents, :document_category
    
    # Add AI processing fields for enhanced document analysis
    add_column :documents, :ai_confidence, :decimal, precision: 5, scale: 4
    add_column :documents, :ai_entities, :jsonb, default: {}
    add_index :documents, :ai_entities, using: :gin
  end
end