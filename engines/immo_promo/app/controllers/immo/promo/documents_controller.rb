module Immo
  module Promo
    class DocumentsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_documentable
      before_action :set_document, only: [:show, :download, :preview, :edit, :update, :destroy, :share, :request_validation]
      before_action :authorize_document_access!, only: [:show, :download, :preview]
      before_action :authorize_document_edit!, only: [:edit, :update, :destroy]
      
      def index
        @documents = @documentable.documents.includes(:file_attachment, :uploaded_by)
        @documents = @documents.where(document_category: params[:category]) if params[:category].present?
        @documents = @documents.where(status: params[:status]) if params[:status].present?
        @documents = @documents.order(created_at: :desc).page(params[:page])
        
        @categories = @documentable.documents.group(:document_category).count
        @statuses = @documentable.documents.group(:status).count
        @statistics = @documentable.document_statistics
      end
      
      def show
        @versions = @document.document_versions.order(version_number: :desc)
        @validations = @document.document_validations.includes(:validator)
        @shares = @document.document_shares.includes(:shared_with_user)
      end
      
      def new
        @document = @documentable.documents.build
        @categories = document_categories_for(@documentable)
      end
      
      def create
        files = params[:documents][:files]
        category = params[:documents][:category]
        
        if files.present?
          @documents = []
          files.each do |file|
            doc = @documentable.attach_document(
              file,
              category: category,
              user: current_user,
              title: params[:documents][:title],
              description: params[:documents][:description]
            )
            @documents << doc
          end
          
          redirect_to immo_promo_engine.polymorphic_path([@documentable, :documents]), 
                      notice: "#{@documents.count} document(s) téléchargé(s) avec succès."
        else
          redirect_to immo_promo_engine.new_polymorphic_path([@documentable, :document]), 
                      alert: "Veuillez sélectionner au moins un fichier."
        end
      end
      
      def edit
        @categories = document_categories_for(@documentable)
      end
      
      def update
        if @document.update(document_params)
          redirect_to immo_promo_engine.polymorphic_path([@documentable, @document]), 
                      notice: "Document mis à jour avec succès."
        else
          render :edit
        end
      end
      
      def destroy
        @document.destroy
        redirect_to polymorphic_path([@documentable, :documents]), 
                    notice: "Document supprimé avec succès."
      end
      
      def download
        redirect_to rails_blob_path(@document.file, disposition: 'attachment')
      end
      
      def preview
        if @document.preview_url
          redirect_to @document.preview_url
        elsif @document.file.previewable?
          redirect_to rails_blob_preview_path(@document.file, disposition: 'inline')
        else
          redirect_to rails_blob_path(@document.file, disposition: 'inline')
        end
      end
      
      def share
        if request.post?
          stakeholder_ids = params[:stakeholder_ids] || []
          permission_level = params[:permission_level] || 'read'
          
          stakeholders = @documentable.stakeholders.where(id: stakeholder_ids)
          shares = @documentable.share_documents_with_stakeholder(
            stakeholders, 
            [@document.id], 
            permission_level: permission_level,
            user: current_user
          )
          
          redirect_to polymorphic_path([@documentable, @document]), 
                      notice: "Document partagé avec #{shares.count} intervenant(s)."
        else
          @stakeholders = @documentable.stakeholders.active
        end
      end
      
      def request_validation
        if request.post?
          validator_ids = params[:validator_ids] || []
          min_validations = params[:min_validations] || 1
          
          validators = User.where(id: validator_ids)
          validation = @documentable.request_document_validation(
            [@document.id],
            validators: validators,
            requester: current_user,
            min_validations: min_validations
          )
          
          redirect_to polymorphic_path([@documentable, @document]), 
                      notice: "Demande de validation envoyée."
        else
          @potential_validators = potential_validators_for(@document)
        end
      end
      
      def bulk_actions
        document_ids = params[:document_ids] || []
        action = params[:bulk_action]
        
        case action
        when 'download'
          # Create a zip file with all selected documents
          # This would require implementing a bulk download service
          redirect_to polymorphic_path([@documentable, :documents]), 
                      notice: "Téléchargement en cours..."
        when 'share'
          session[:bulk_document_ids] = document_ids
          redirect_to share_bulk_polymorphic_path([@documentable, :documents])
        when 'delete'
          @documentable.documents.where(id: document_ids).destroy_all
          redirect_to polymorphic_path([@documentable, :documents]), 
                      notice: "Documents supprimés avec succès."
        else
          redirect_to polymorphic_path([@documentable, :documents]), 
                      alert: "Action non reconnue."
        end
      end
      
      private
      
      def set_documentable
        # Determine the parent object (Project, Permit, Task, etc.)
        if params[:project_id]
          @documentable = Project.find(params[:project_id])
          @project = @documentable
        elsif params[:permit_id]
          @permit = Permit.find(params[:permit_id])
          @documentable = @permit
          @project = @permit.project
        elsif params[:task_id]
          @task = Task.find(params[:task_id])
          @documentable = @task
          @project = @task.phase.project
        elsif params[:phase_id]
          @phase = Phase.find(params[:phase_id])
          @documentable = @phase
          @project = @phase.project
        elsif params[:stakeholder_id]
          @stakeholder = Stakeholder.find(params[:stakeholder_id])
          @documentable = @stakeholder
          @project = @stakeholder.project
        else
          raise ActiveRecord::RecordNotFound
        end
        
        authorize @project, :show?
      end
      
      def set_document
        @document = @documentable.documents.find(params[:id])
      end
      
      def document_params
        params.require(:document).permit(:title, :description, :document_category, :status)
      end
      
      def authorize_document_access!
        unless can_access_document?(@document)
          redirect_to polymorphic_path([@documentable, :documents]), 
                      alert: "Vous n'avez pas accès à ce document."
        end
      end
      
      def authorize_document_edit!
        unless can_edit_document?(@document)
          redirect_to polymorphic_path([@documentable, :documents]), 
                      alert: "Vous ne pouvez pas modifier ce document."
        end
      end
      
      def can_access_document?(document)
        # Project managers and admins can access all documents
        return true if current_user.has_role?(:admin) || @project.project_manager == current_user
        
        # Check if user has explicit access
        document.documents_readable_by(current_user).exists? ||
          document.uploaded_by == current_user
      end
      
      def can_edit_document?(document)
        # Only admins, project managers, and document owners can edit
        current_user.has_role?(:admin) || 
          @project.project_manager == current_user ||
          document.uploaded_by == current_user
      end
      
      def document_categories_for(documentable)
        case documentable
        when Project
          %w[project technical administrative financial legal permit plan]
        when Permit
          %w[permit administrative legal]
        when Task
          %w[technical financial]
        when Phase
          %w[project technical administrative]
        when Stakeholder
          %w[contract administrative legal financial]
        else
          %w[project technical administrative financial legal]
        end
      end
      
      def potential_validators_for(document)
        # Get users who can validate this type of document
        case document.document_category
        when 'permit'
          User.joins(:user_groups).where(user_groups: { name: ['Architects', 'Project Managers'] })
        when 'financial'
          User.joins(:user_groups).where(user_groups: { name: ['Finance', 'Controllers'] })
        when 'technical'
          User.joins(:user_groups).where(user_groups: { name: ['Engineers', 'Architects'] })
        else
          @project.stakeholders.map(&:user).compact
        end
      end
    end
  end
end