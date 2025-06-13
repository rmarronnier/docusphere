class CreateClientRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :client_relationships do |t|
      t.references :client, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :relationship_type

      t.timestamps
    end
  end
end
