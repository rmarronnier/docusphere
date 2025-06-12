class AddViewTrackingToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :last_viewed_at, :datetime unless column_exists?(:documents, :last_viewed_at)
    add_column :documents, :last_viewed_by_id, :bigint unless column_exists?(:documents, :last_viewed_by_id)
    
    add_index :documents, :last_viewed_at unless index_exists?(:documents, :last_viewed_at)
    add_index :documents, :last_viewed_by_id unless index_exists?(:documents, :last_viewed_by_id)
    
    # Add foreign key constraint if not exists
    unless foreign_key_exists?(:documents, :users, column: :last_viewed_by_id)
      add_foreign_key :documents, :users, column: :last_viewed_by_id
    end
  end
end