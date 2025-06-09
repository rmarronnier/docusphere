class DocumentValidationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document
  before_action :set_validation_request, only: [:show, :approve, :reject]
  before_action :set_document_validation, only: [:approve, :reject]
  before_action :ensure_can_request_validation, only: [:new, :create]
  before_action :ensure_can_validate, only: [:approve, :reject]
  
  def index
    # Show all validation requests for the current user (as validator)
    @pending_validations = current_user.document_validations
                                      .includes(:document, :validation_request)
                                      .pending
                                      .page(params[:page])
    
    @completed_validations = current_user.document_validations
                                        .includes(:document, :validation_request)
                                        .completed
                                        .order(validated_at: :desc)
                                        .page(params[:completed_page])
  end
  
  def show
    # Show details of a specific validation request
    @document_validations = @validation_request.document_validations.includes(:validator)
    @can_validate = @validation_request.document_validations.exists?(validator: current_user, status: 'pending')
  end
  
  def new
    # Form to create a new validation request
    @validation_request = @document.validation_requests.build
    @available_validators = User.joins(:authorizations)
                               .where(authorizations: { 
                                 authorizable: @document.space,
                                 permission_level: ['validate', 'admin']
                               })
                               .distinct
  end
  
  def create
    # Create a new validation request
    validator_ids = params[:validation_request][:validator_ids].reject(&:blank?)
    min_validations = params[:validation_request][:min_validations].to_i
    
    if validator_ids.empty?
      redirect_to ged_document_path(@document), alert: "Veuillez sélectionner au moins un validateur"
      return
    end
    
    if min_validations > validator_ids.count
      redirect_to ged_document_path(@document), alert: "Le nombre minimum de validations ne peut pas dépasser le nombre de validateurs"
      return
    end
    
    validators = User.where(id: validator_ids)
    
    @validation_request = @document.request_validation(
      requester: current_user,
      validators: validators,
      min_validations: min_validations
    )
    
    if @validation_request.persisted?
      redirect_to ged_document_path(@document), notice: "Demande de validation créée avec succès"
    else
      redirect_to ged_document_path(@document), alert: "Erreur lors de la création de la demande de validation"
    end
  end
  
  def approve
    # Approve a document validation
    comment = params[:comment].presence
    
    if @document_validation.approve!(comment: comment)
      respond_to do |format|
        format.html { redirect_to document_validation_path(@document, @validation_request), notice: "Document approuvé avec succès" }
        format.json { render json: { status: 'approved', message: 'Document approuvé' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to document_validation_path(@document, @validation_request), alert: "Erreur lors de l'approbation" }
        format.json { render json: { status: 'error', message: @document_validation.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end
  
  def reject
    # Reject a document validation
    comment = params[:comment].presence
    
    if comment.blank?
      respond_to do |format|
        format.html { redirect_to document_validation_path(@document, @validation_request), alert: "Un commentaire est requis pour refuser un document" }
        format.json { render json: { status: 'error', message: 'Commentaire requis' }, status: :unprocessable_entity }
      end
      return
    end
    
    if @document_validation.reject!(comment: comment)
      respond_to do |format|
        format.html { redirect_to document_validation_path(@document, @validation_request), notice: "Document refusé" }
        format.json { render json: { status: 'rejected', message: 'Document refusé' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to document_validation_path(@document, @validation_request), alert: "Erreur lors du refus" }
        format.json { render json: { status: 'error', message: @document_validation.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end
  
  def my_requests
    # Show validation requests created by the current user
    @validation_requests = ValidationRequest.for_requester(current_user)
                                          .includes(:document, :document_validations)
                                          .order(created_at: :desc)
                                          .page(params[:page])
  end
  
  private
  
  def set_document
    @document = Document.find(params[:document_id])
  end
  
  def set_validation_request
    @validation_request = @document.validation_requests.find(params[:id])
  end
  
  def set_document_validation
    @document_validation = @validation_request.document_validations.find_by!(validator: current_user)
  end
  
  def ensure_can_request_validation
    unless @document.can_request_validation?(current_user)
      redirect_to ged_document_path(@document), alert: "Vous n'avez pas la permission de demander une validation pour ce document"
    end
  end
  
  def ensure_can_validate
    unless @document_validation && @document_validation.pending?
      redirect_to ged_document_path(@document), alert: "Vous ne pouvez pas valider ce document"
    end
  end
end