module Immo
  module Promo
    class DocumentsController < Immo::Promo::ApplicationController
      before_action :authenticate_user!
      before_action :set_documentable
      before_action :set_document, only: [:show, :download, :preview, :edit, :update, :destroy, :share, :request_validation]
      before_action :authorize_document_access!, only: [:show, :download, :preview]
      before_action :authorize_document_edit!, only: [:edit, :update, :destroy]
      
      def index
        authorize @project
        @documents = @documentable.documents.includes(:uploaded_by)
        @documents = @documents.where(document_category: params[:category]) if params[:category].present?
        @documents = @documents.where(status: params[:status]) if params[:status].present?
        @documents = @documents.order(created_at: :desc)
        
        @categories = @documentable.documents.group(:document_category).count
        @statuses = @documentable.documents.group(:status).count
        @statistics = { total_documents: @documents.count }
      end
      
      def show
        authorize @document
        @versions = @document.versions.order(created_at: :desc)
        @validations = @document.document_validations.includes(:validator)
        @shares = @document.document_shares.includes(:shared_with_user)
      end
      
      def new
        @document = @documentable.documents.build
        authorize @document
        @categories = document_categories_for(@documentable)
      end
      
      def create
        @document = @documentable.documents.build
        authorize @document
        files = params[:documents][:files]
        category = params[:documents][:category]
        
        if files.present?
          @documents = []
          # Create or get a default space for the project documents
          space = Space.find_or_create_by(
            name: "#{@project.name} Documents",
            organization: current_user.organization
          )
          
          files.each do |file|
            doc = Document.create!(
              file: file,
              document_category: category,
              uploaded_by: current_user,
              title: params[:documents][:title],
              description: params[:documents][:description],
              space: space,
              documentable: @documentable
            )
            @documents << doc
          end
          
          redirect_to immo_promo_engine.project_documents_path(@project), 
                      notice: "#{@documents.count} document(s) téléchargé(s) avec succès."
        else
          redirect_to immo_promo_engine.new_project_document_path(@project), 
                      alert: "Veuillez sélectionner au moins un fichier."
        end
      end
      
      def edit
        authorize @document
        @categories = document_categories_for(@documentable)
      end
      
      def update
        authorize @document
        if @document.update(document_params)
          redirect_to immo_promo_engine.project_document_path(@project, @document), 
                      notice: "Document mis à jour avec succès."
        else
          render :edit
        end
      end
      
      def destroy
        authorize @document
        @document.destroy
        redirect_to immo_promo_engine.project_documents_path(@project), 
                    notice: "Document supprimé avec succès."
      end
      
      def download
        authorize @document
        redirect_to rails_blob_path(@document.file, disposition: 'attachment')
      end
      
      def preview
        authorize @document
        if @document.file.attached?
          redirect_to rails_blob_path(@document.file, disposition: 'inline')
        else
          redirect_to immo_promo_engine.project_documents_path(@project), alert: "Aucun fichier attaché"
        end
      end
      
      def share
        authorize @document
        if request.post?
          stakeholder_ids = params[:stakeholder_ids] || []
          permission_level = params[:permission_level] || 'read'
          
          # Simplified sharing - just create document shares
          stakeholder_ids.each do |stakeholder_id|
            stakeholder = Immo::Promo::Stakeholder.find(stakeholder_id)
            DocumentShare.create(
              document: @document,
              email: stakeholder.email,
              access_level: permission_level,
              shared_by: current_user
            )
          end
          
          redirect_to immo_promo_engine.project_document_path(@project, @document), 
                      notice: "Document partagé avec #{stakeholder_ids.count} intervenant(s)."
        else
          @stakeholders = @project.stakeholders
        end
      end
      
      def request_validation
        authorize @document
        if request.post?
          validator_ids = params[:validator_ids] || []
          min_validations = params[:min_validations] || 1
          
          # Create a validation request
          validation_request = ValidationRequest.create!(
            validatable: @document,
            requester: current_user,
            min_validations: min_validations,
            status: 'pending'
          )
          
          # Add validators via document_validations
          validator_ids.each do |validator_id|
            DocumentValidation.create!(
              validatable: @document,
              validation_request: validation_request,
              validator_id: validator_id,
              status: 'pending'
            )
          end
          
          redirect_to immo_promo_engine.project_document_path(@project, @document), 
                      notice: "Demande de validation envoyée."
        else
          @potential_validators = User.where(organization: current_user.organization)
        end
      end
      
      def bulk_actions
        # Pour les actions en lot, on vérifie que l'utilisateur peut accéder au projet
        authorize @documentable, :update?
        document_ids = params[:document_ids] || []
        action = params[:bulk_action]
        
        case action
        when 'download'
          redirect_to immo_promo_engine.project_documents_path(@project), 
                      notice: "Téléchargement en cours..."
        when 'share'
          session[:bulk_document_ids] = document_ids
          redirect_to immo_promo_engine.project_documents_path(@project)
        when 'delete'
          @documentable.documents.where(id: document_ids).destroy_all
          redirect_to immo_promo_engine.project_documents_path(@project), 
                      notice: "Documents supprimés avec succès."
        else
          redirect_to immo_promo_engine.project_documents_path(@project), 
                      alert: "Action non reconnue."
        end
      end
      
      private
      
      def set_documentable
        # Pour simplifier, ne gérer que les projets pour l'instant
        if params[:project_id]
          @project = policy_scope(Immo::Promo::Project).find(params[:project_id])
          @documentable = @project
        else
          raise ActiveRecord::RecordNotFound
        end
      end
      
      def set_document
        @document = @documentable.documents.find(params[:id])
      end
      
      def document_params
        permitted_attributes(@document || Document.new)
      end
      
      def authorize_document_access!
        unless can_access_document?(@document)
          redirect_to immo_promo_engine.project_documents_path(@project), 
                      alert: "Vous n'avez pas accès à ce document."
        end
      end
      
      def authorize_document_edit!
        unless can_edit_document?(@document)
          redirect_to immo_promo_engine.project_documents_path(@project), 
                      alert: "Vous ne pouvez pas modifier ce document."
        end
      end
      
      def can_access_document?(document)
        # Project managers and admins can access all documents
        return true if current_user.admin? || @project.project_manager == current_user
        
        # Check if user has explicit access
        document.uploaded_by == current_user
      end
      
      def can_edit_document?(document)
        # Only admins, project managers, and document owners can edit
        current_user.admin? || 
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