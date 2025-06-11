module Ged
  module DocumentOperations
    extend ActiveSupport::Concern

    def document_status
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :show?
      
      status_info = {
        status: @document.status,
        processing_status: @document.processing_status,
        virus_scan_status: @document.virus_scan_status,
        locked: @document.locked?,
        locked_by: @document.locked_by&.full_name,
        locked_at: @document.locked_at,
        unlock_scheduled_at: @document.unlock_scheduled_at,
        ai_processed: @document.ai_processed?,
        ai_category: @document.ai_category,
        ai_confidence: @document.ai_confidence,
        tags: @document.tags.pluck(:name),
        metadata: @document.metadata,
        view_count: @document.view_count,
        download_count: @document.download_count,
        last_viewed_at: @document.last_viewed_at,
        created_at: @document.created_at,
        updated_at: @document.updated_at
      }
      
      render json: status_info
    end

    def download_document
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :show?
      @document.increment_download_count!
      redirect_to rails_blob_url(@document.file, disposition: 'attachment')
    end

    def preview_document
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :show?
      @document.increment_view_count!
      
      if @document.previewable?
        redirect_to rails_blob_url(@document.file, disposition: 'inline')
      else
        render json: {
          error: 'Ce type de document ne peut pas être prévisualisé',
          content_type: @document.content_type
        }, status: :unprocessable_entity
      end
    end

    def upload_document
      # Extract space_id from params or document params
      space_id = params[:space_id] || params.dig(:document, :space_id)
      folder_id = params[:folder_id] || params.dig(:document, :folder_id)
      
      if space_id.present?
        @space = policy_scope(Space).find(space_id)
        @folder = policy_scope(Folder).find(folder_id) if folder_id.present?
      end
      
      authorize Document.new(space: @space), :create?
      
      @document = Document.new(document_params)
      @document.space = @space if @space
      @document.folder = @folder if @folder
      @document.uploaded_by = current_user
      
      if @document.save
        # Trigger background jobs
        DocumentProcessingJob.perform_later(@document)
        VirusScanJob.perform_later(@document) if @document.file.attached?
        
        render json: {
          success: true,
          message: 'Document uploadé avec succès. Le traitement est en cours...',
          document: {
            id: @document.id,
            title: @document.title,
            status: @document.status,
            processing_status: @document.processing_status
          }
        }
      else
        render json: {
          success: false,
          errors: @document.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end