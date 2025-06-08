class AddAuthorizationFields < ActiveRecord::Migration[7.1]
  def change
    add_reference :authorizations, :granted_by, null: true, foreign_key: { to_table: :users }
    add_column :authorizations, :granted_at, :datetime
    add_column :authorizations, :expired_at, :datetime
    add_column :authorizations, :revoked_at, :datetime
    add_reference :authorizations, :revoked_by, null: true, foreign_key: { to_table: :users }
    add_column :authorizations, :comment, :text
  end
end
