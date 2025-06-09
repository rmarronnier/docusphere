module Immo
  module Promo
    class DocumentsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_documentable, only: [:index, :create, :bulk_upload]
      before_action :set_document, only: [:show, :download, :update, :destroy]
      before_action :authorize_documentable_access!, only: [:index, :create, :bulk_upload]
      before_action :authorize_document_access!, only: [:show, :download, :update, :destroy]

      # GET /immo/promo/projects/:project_id/documents
      # GET /immo/promo/phases/:phase_id/documents
      # GET /immo/promo/tasks/:task_id/documents
      # GET /immo/promo/permits/:permit_id/documents
      # GET /immo/promo/stakeholders/:stakeholder_id/documents
      def index
        @documents = @documentable.documents.includes(:tags, :uploaded_by)
        @documents = @documents.where(document_category: params[:category]) if params[:category].present?
        @documents = @documents.where(status: params[:status]) if params[:status].present?
        @documents = @documents.page(params[:page]).per(20)

        @document_statistics = @documentable.document_statistics
        @workflow_status = @documentable.document_workflow_status
        @missing_documents = @documentable.missing_critical_documents

        respond_to do |format|
          format.html
          format.json { render json: @documents }
        end
      end

      # GET /immo/promo/documents/:id
      def show
        @document_versions = @document.document_versions.order(version_number: :desc)
        @validation_status = @document.validation_summary
        @shares = @document.document_shares.includes(:shared_with_user)

        respond_to do |format|
          format.html
          format.json { render json: @document.as_json(include: [:tags, :uploaded_by, :document_versions]) }
        end
      end

      # POST /immo/promo/projects/:project_id/documents
      def create
        # Create a temporary document object for authorization
        temp_document = ::Document.new(documentable: @documentable)
        authorize temp_document, :create?, policy_class: Immo::Promo::DocumentPolicy
        
        @document = @documentable.attach_document(
          document_params[:file],
          category: document_params[:document_category] || 'project',
          user: current_user,
          title: document_params[:title],
          description: document_params[:description]
        )

        if @document.persisted?
          # Add tags if provided
          if document_params[:tag_list].present?
            tag_names = document_params[:tag_list].split(',').map(&:strip)
            @document.tags = ::Tag.where(name: tag_names).or(::Tag.where(name: tag_names.map { |name| ::Tag.create!(name: name).name }))
          end

          respond_to do |format|
            format.html { redirect_to documentable_documents_path, notice: 'Document uploaded successfully.' }
            format.json { render json: @document, status: :created }
          end
        else
          respond_to do |format|
            format.html { redirect_to documentable_documents_path, alert: @document.errors.full_messages.join(', ') }
            format.json { render json: { errors: @document.errors }, status: :unprocessable_entity }
          end
        end
      end

      # POST /immo/promo/projects/:project_id/documents/bulk_upload
      def bulk_upload
        # Create a temporary document object for authorization
        temp_document = ::Document.new(documentable: @documentable)
        authorize temp_document, :bulk_upload?, policy_class: Immo::Promo::DocumentPolicy
        
        if params[:files].present?
          @documents = @documentable.attach_multiple_documents(
            params[:files],
            category: params[:document_category] || 'project',
            user: current_user
          )

          successful_uploads = @documents.select(&:persisted?)
          failed_uploads = @documents.reject(&:persisted?)

          if failed_uploads.empty?
            respond_to do |format|
              format.html { redirect_to documentable_documents_path, notice: "#{successful_uploads.count} documents uploaded successfully." }
              format.json { render json: { success: true, uploaded: successful_uploads.count } }
            end
          else
            error_messages = failed_uploads.map { |doc| doc.errors.full_messages }.flatten
            respond_to do |format|
              format.html { redirect_to documentable_documents_path, alert: "Some uploads failed: #{error_messages.join(', ')}" }
              format.json { render json: { errors: error_messages, uploaded: successful_uploads.count }, status: :unprocessable_entity }
            end
          end
        else
          respond_to do |format|
            format.html { redirect_to documentable_documents_path, alert: 'No files selected for upload.' }
            format.json { render json: { error: 'No files provided' }, status: :bad_request }
          end
        end
      end

      # GET /immo/promo/documents/:id/download
      def download
        if @document.file.attached?
          redirect_to rails_blob_path(@document.file, disposition: "attachment")
        else
          respond_to do |format|
            format.html { redirect_back(fallback_location: root_path, alert: 'File not found.') }
            format.json { render json: { error: 'File not found' }, status: :not_found }
          end
        end
      end

      # PATCH/PUT /immo/promo/documents/:id
      def update
        authorize @document, :update?, policy_class: Immo::Promo::DocumentPolicy
        
        if @document.update(document_update_params)
          # Update tags if provided
          if document_update_params[:tag_list].present?
            tag_names = document_update_params[:tag_list].split(',').map(&:strip)
            @document.tags = ::Tag.where(name: tag_names).or(::Tag.where(name: tag_names.map { |name| ::Tag.create!(name: name).name }))
          end

          respond_to do |format|
            format.html { redirect_to immo_promo_engine.document_path(@document), notice: 'Document updated successfully.' }
            format.json { render json: @document }
          end
        else
          respond_to do |format|
            format.html { render :show, status: :unprocessable_entity }
            format.json { render json: { errors: @document.errors }, status: :unprocessable_entity }
          end
        end
      end

      # DELETE /immo/promo/documents/:id
      def destroy
        authorize @document, :destroy?, policy_class: Immo::Promo::DocumentPolicy
        
        documentable = @document.documentable
        @document.destroy

        respond_to do |format|
          format.html { redirect_to documentable_documents_path(documentable), notice: 'Document deleted successfully.' }
          format.json { head :no_content }
        end
      end

      # POST /immo/promo/documents/:id/share
      def share_document
        @document = ::Document.find(params[:id])
        authorize_document_access!

        if params[:stakeholder_ids].present? && params[:permission_level].present?
          stakeholders = @document.documentable.project.stakeholders.where(id: params[:stakeholder_ids])
          shares = @document.documentable.share_documents_with_stakeholder(
            stakeholders.first, 
            [@document.id], 
            permission_level: params[:permission_level],
            user: current_user
          )

          respond_to do |format|
            format.html { redirect_to immo_promo_engine.document_path(@document), notice: 'Document shared successfully.' }
            format.json { render json: { success: true, shares: shares.count } }
          end
        else
          respond_to do |format|
            format.html { redirect_to immo_promo_engine.document_path(@document), alert: 'Please select stakeholders and permission level.' }
            format.json { render json: { error: 'Invalid parameters' }, status: :bad_request }
          end
        end
      end

      # POST /immo/promo/documents/:id/request_validation
      def request_validation
        @document = ::Document.find(params[:id])
        authorize_document_access!

        if params[:validator_ids].present?
          validators = User.where(id: params[:validator_ids])
          validation_request = @document.request_validation(
            requester: current_user,
            validators: validators,
            min_validations: params[:min_validations] || 1
          )

          respond_to do |format|
            format.html { redirect_to immo_promo_engine.document_path(@document), notice: 'Validation request sent successfully.' }
            format.json { render json: { success: true, validation_request: validation_request.id } }
          end
        else
          respond_to do |format|
            format.html { redirect_to immo_promo_engine.document_path(@document), alert: 'Please select validators.' }
            format.json { render json: { error: 'No validators selected' }, status: :bad_request }
          end
        end
      end

      # GET /immo/promo/documents/search
      def search
        @query = params[:q]
        @category = params[:category]
        @documentable_type = params[:documentable_type]

        @documents = ::Document.where(documentable_type: ['Immo::Promo::Project', 'Immo::Promo::Phase', 'Immo::Promo::Task', 'Immo::Promo::Permit', 'Immo::Promo::Stakeholder'])
        
        if @query.present?
          @documents = @documents.where("title ILIKE ? OR description ILIKE ? OR content ILIKE ?", 
                                       "%#{@query}%", "%#{@query}%", "%#{@query}%")
        end

        @documents = @documents.where(document_category: @category) if @category.present?
        @documents = @documents.where(documentable_type: @documentable_type) if @documentable_type.present?

        # Only show documents the user can access
        @documents = @documents.joins(:authorizations)
                              .where(authorizations: { 
                                user: current_user, 
                                permission_level: ['read', 'write', 'admin'] 
                              })
                              .or(@documents.where(uploaded_by: current_user))
                              .distinct

        @documents = @documents.includes(:documentable, :uploaded_by, :tags).page(params[:page]).per(20)

        respond_to do |format|
          format.html
          format.json { render json: @documents }
        end
      end

      private

      def set_documentable
        if params[:project_id]
          @documentable = Immo::Promo::Project.find(params[:project_id])
        elsif params[:phase_id]
          @documentable = Immo::Promo::Phase.find(params[:phase_id])
        elsif params[:task_id]
          @documentable = Immo::Promo::Task.find(params[:task_id])
        elsif params[:permit_id]
          @documentable = Immo::Promo::Permit.find(params[:permit_id])
        elsif params[:stakeholder_id]
          @documentable = Immo::Promo::Stakeholder.find(params[:stakeholder_id])
        else
          redirect_to root_path, alert: 'Invalid resource.'
        end
      end

      def set_document
        @document = ::Document.find(params[:id])
      end

      def authorize_documentable_access!
        case @documentable
        when Immo::Promo::Project
          authorize @documentable, :show?
        when Immo::Promo::Phase, Immo::Promo::Task, Immo::Promo::Permit, Immo::Promo::Stakeholder
          authorize @documentable.project, :show?
        end
      end

      def authorize_document_access!
        authorize @document, :show?, policy_class: Immo::Promo::DocumentPolicy
      rescue Pundit::NotAuthorizedError
        respond_to do |format|
          format.html { redirect_to root_path, alert: 'Access denied.' }
          format.json { render json: { error: 'Access denied' }, status: :forbidden }
        end
      end

      def document_params
        params.require(:document).permit(:title, :description, :file, :document_category, :tag_list)
      end

      def document_update_params
        params.require(:document).permit(:title, :description, :document_category, :tag_list)
      end

      def documentable_documents_path(documentable = @documentable)
        case documentable
        when Immo::Promo::Project
          immo_promo_engine.project_documents_path(documentable)
        when Immo::Promo::Phase
          immo_promo_engine.phase_documents_path(documentable)
        when Immo::Promo::Task
          immo_promo_engine.task_documents_path(documentable)
        when Immo::Promo::Permit
          immo_promo_engine.permit_documents_path(documentable)
        when Immo::Promo::Stakeholder
          immo_promo_engine.stakeholder_documents_path(documentable)
        else
          immo_promo_engine.root_path
        end
      end
    end
  end
end