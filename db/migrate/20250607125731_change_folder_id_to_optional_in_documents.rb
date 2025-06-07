class ChangeFolderIdToOptionalInDocuments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :documents, :folder_id, true
  end
end
