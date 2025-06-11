module Ged
  module DocumentVersioning
    extend ActiveSupport::Concern

    def document_versions
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :show?
      
      @versions = @document.versions
                          .includes(:created_by)
                          .order(created_at: :desc)
                          .page(params[:page])
      
      render json: {
        versions: @versions.map { |v| serialize_version(v) },
        pagination: pagination_meta(@versions)
      }
    end

    def create_document_version
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :update?
      
      if @document.locked? && @document.locked_by != current_user
        render json: {
          success: false,
          error: "Document verrouillé par #{@document.locked_by.full_name}"
        }, status: :conflict
        return
      end

      ActiveRecord::Base.transaction do
        # Create new version with current document state
        @document.paper_trail.save_with_version(
          event: 'create',
          whodunnit: current_user.id,
          comment: version_params[:comment]
        )

        # Update document with new content if provided
        if params[:file].present?
          @document.file.attach(params[:file])
          @document.update!(
            file_size: @document.file.blob.byte_size,
            content_type: @document.file.blob.content_type,
            updated_by: current_user
          )
        end

        render json: {
          success: true,
          message: 'Nouvelle version créée avec succès',
          version: serialize_version(@document.versions.last)
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        errors: e.record.errors.full_messages
      }, status: :unprocessable_entity
    end

    def restore_document_version
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :update?
      
      version = @document.versions.find(params[:version_id])
      
      if @document.locked? && @document.locked_by != current_user
        render json: {
          success: false,
          error: "Document verrouillé par #{@document.locked_by.full_name}"
        }, status: :conflict
        return
      end

      ActiveRecord::Base.transaction do
        # Restore document attributes from version
        @document.paper_trail.revert_to!(version.index)
        
        # Create a new version for the restoration
        @document.paper_trail.save_with_version(
          event: 'restore',
          whodunnit: current_user.id,
          comment: "Restauration de la version #{version.version_number}"
        )

        render json: {
          success: true,
          message: 'Document restauré avec succès',
          version: serialize_version(@document.versions.last)
        }
      end
    rescue StandardError => e
      render json: {
        success: false,
        error: "Erreur lors de la restauration: #{e.message}"
      }, status: :internal_server_error
    end

    def download_document_version
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :show?
      
      version = @document.versions.find(params[:version_id])
      
      # Reconstruct document state at this version
      versioned_document = version.reify
      
      if versioned_document&.file&.attached?
        redirect_to rails_blob_url(versioned_document.file, disposition: 'attachment')
      else
        render json: {
          error: 'Fichier non disponible pour cette version'
        }, status: :not_found
      end
    end

    private

    def version_params
      params.permit(:comment)
    end

    def serialize_version(version)
      {
        id: version.id,
        version_number: version.version_number,
        event: version.event,
        created_at: version.created_at,
        created_by: version.created_by&.full_name,
        comment: version.comment,
        changes: version.object_changes
      }
    end

    def pagination_meta(collection)
      {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    end
  end
end