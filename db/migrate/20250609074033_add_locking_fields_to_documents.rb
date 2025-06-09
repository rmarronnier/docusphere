class AddLockingFieldsToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :locked_by_id, :integer
    add_column :documents, :locked_at, :datetime
    add_column :documents, :unlock_scheduled_at, :datetime
    add_column :documents, :lock_reason, :text
    
    add_index :documents, :locked_by_id
    add_index :documents, :unlock_scheduled_at
    add_foreign_key :documents, :users, column: :locked_by_id
  end
end
