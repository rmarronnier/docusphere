class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.text :description
      t.text :content
      t.text :extracted_content
      t.string :status
      t.references :user, null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true
      t.references :folder, null: false, foreign_key: true
      t.date :retention_date
      t.date :destruction_date

      t.timestamps
    end
  end
end
