class AddValidationRequestToDocumentValidations < ActiveRecord::Migration[7.1]
  def change
    add_reference :document_validations, :validation_request, null: false, foreign_key: true
  end
end
