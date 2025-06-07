class CreateAuthorizations < ActiveRecord::Migration[7.1]
  def change
    create_table :authorizations do |t|
      t.references :authorizable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.references :user_group, null: false, foreign_key: true
      t.string :permission_type

      t.timestamps
    end
  end
end
