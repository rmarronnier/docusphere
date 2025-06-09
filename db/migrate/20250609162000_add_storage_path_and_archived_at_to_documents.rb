class AddStoragePathAndArchivedAtToDocuments < ActiveRecord::Migration[7.1]
  def change
    # Add storage_path for Storable concern
    unless column_exists?(:documents, :storage_path)
      add_column :documents, :storage_path, :string
      add_index :documents, :storage_path
    end
    
    # Add archived_at for archiving functionality if it doesn't exist
    unless column_exists?(:documents, :archived_at)
      add_column :documents, :archived_at, :datetime
      add_index :documents, :archived_at
    end
    
    # Also add to folders since they use Storable
    unless column_exists?(:folders, :storage_path)
      add_column :folders, :storage_path, :string
      add_index :folders, :storage_path
    end
    
    unless column_exists?(:folders, :archived_at)
      add_column :folders, :archived_at, :datetime
      add_index :folders, :archived_at
    end
  end
end