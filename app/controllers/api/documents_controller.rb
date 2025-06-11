class Api::DocumentsController < Api::BaseController
  def index
    documents = current_user.organization.documents
                          .includes(:uploaded_by, :space)
                          .limit(50)
    
    render_json({
      documents: documents.map { |doc| document_json(doc) }
    })
  end
  
  def my_documents
    documents = current_user.organization.documents
                          .where(uploaded_by: current_user)
                          .recent
                          .limit(10)
    
    render_json({
      documents: documents.map { |doc| document_json(doc) }
    })
  end
  
  def upload
    # Placeholder for upload functionality
    render_json({ message: "Upload endpoint available" })
  end
  
  private
  
  def document_json(document)
    {
      id: document.id,
      title: document.title,
      file_size: document.file.attached? ? document.file.byte_size : 0,
      created_at: document.created_at,
      url: ged_document_path(document)
    }
  end
end