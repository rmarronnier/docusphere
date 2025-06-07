class CreateUserGroupMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :user_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_group, null: false, foreign_key: true
      t.string :role
      t.text :permissions

      t.timestamps
    end
  end
end
