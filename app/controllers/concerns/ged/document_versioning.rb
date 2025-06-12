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
      
      respond_to do |format|
        format.html do
          @breadcrumbs = build_document_breadcrumbs(@document)
        end
        format.json do
          render json: {
            versions: @versions.map { |v| serialize_version(v) },
            pagination: pagination_meta(@versions)
          }
        end
      end
    end

    def create_document_version
      @document = policy_scope(Document).find(params[:id])
      authorize @document, :update?
      
      if @document.locked? && @document.locked_by != current_user
        respond_to do |format|
          format.json do
            render json: {
              success: false,
              error: "Document verrouillé par #{@document.locked_by.full_name}"
            }, status: :conflict
          end
          format.html do
            redirect_back(fallback_location: ged_document_path(@document), 
                         alert: "Document verrouillé par #{@document.locked_by.full_name}")
          end
        end
        return
      end

      ActiveRecord::Base.transaction do
        # Set Current.user for PaperTrail
        Current.user = current_user
        
        # Get the uploaded file from version params
        uploaded_file = params.dig(:version, :file)
        version_comment = params.dig(:version, :comment) || "Mise à jour des conditions générales"
        
        if uploaded_file.present?
          # Create a new version using the Versionable concern method
          version = @document.create_version!(uploaded_file, current_user, version_comment)
          
          if version
            new_version_number = @document.current_version_number
            
            respond_to do |format|
              format.json do
                render json: {
                  success: true,
                  message: 'Nouvelle version créée avec succès',
                  version: serialize_version(version)
                }
              end
              format.html do
                flash[:notice] = "Version #{new_version_number} créée avec succès"
                redirect_to ged_document_path(@document)
              end
            end
          else
            raise "Impossible de créer la version"
          end
        else
          raise "Aucun fichier fourni"
        end
      end
    rescue => e
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: [e.message]
          }, status: :unprocessable_entity
        end
        format.html do
          redirect_back(fallback_location: ged_document_path(@document), 
                       alert: "Erreur : #{e.message}")
        end
      end
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