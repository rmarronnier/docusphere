class CreateDocumentValidations < ActiveRecord::Migration[7.1]
  def change
    create_table :document_validations do |t|
      t.references :document, null: false, foreign_key: true
      t.references :validator, null: false, foreign_key: { to_table: :users }
      t.string :status
      t.text :comment
      t.datetime :validated_at

      t.timestamps
    end
  end
end
