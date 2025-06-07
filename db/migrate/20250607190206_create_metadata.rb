class CreateMetadata < ActiveRecord::Migration[7.1]
  def change
    create_table :metadata do |t|
      t.references :document, null: false, foreign_key: true
      t.string :key
      t.text :value
      t.string :metadata_type

      t.timestamps
    end
  end
end
