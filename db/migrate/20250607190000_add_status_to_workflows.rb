class AddStatusToWorkflows < ActiveRecord::Migration[7.1]
  def change
    add_column :workflows, :status, :string, default: 'draft'
    add_index :workflows, :status
  end
end