class AddPriorityToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :priority, :string, default: 'normal'
    add_index :notifications, :priority
    add_index :notifications, [:user_id, :read_at, :priority]
  end
end
