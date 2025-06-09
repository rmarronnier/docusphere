class GedController < ApplicationController
  before_action :authenticate_user!
  before_action :set_space, only: [:show_space, :create_folder]
  before_action :set_folder, only: [:show_folder]
  before_action :set_document, only: [:show_document, :lock_document, :unlock_document]
  skip_after_action :verify_authorized, only: [:dashboard]

  def dashboard
    @favorite_spaces = policy_scope(Space).limit(6)
    @recent_documents = policy_scope(Document).where(uploaded_by: current_user)
                                             .includes(:space, :folder)
                                             .order(updated_at: :desc)
                                             .limit(10)
    @spaces_count = policy_scope(Space).count
    @documents_count = policy_scope(Document).count
  end

  def show_space
    # authorize already called in set_space
    @folders = @space.folders.roots.includes(:children)
    @documents = @space.documents.where(folder: nil).includes(:uploaded_by)
    @breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }, { name: @space.name, path: ged_space_path(@space) }]
  end

  def show_folder
    # authorize already called in set_folder
    @space = @folder.space
    @subfolders = @folder.children.includes(:children)
    @documents = @folder.documents.includes(:uploaded_by)
    @breadcrumbs = build_folder_breadcrumbs(@folder)
  end

  def show_document
    # authorize already called in set_document
    @space = @document.space
    @folder = @document.folder
    @breadcrumbs = build_document_breadcrumbs(@document)
  end

  def create_space
    @space = current_user.organization.spaces.build(space_params)
    authorize @space, :create?
    
    if @space.save
      render json: { success: true, message: 'Espace créé avec succès', redirect_url: ged_space_path(@space) }
    else
      render json: { success: false, errors: @space.errors.full_messages }
    end
  end

  def create_folder
    # authorize already called in set_space
    @folder = @space.folders.build(folder_params)
    @folder.parent_id = params[:parent_id] if params[:parent_id].present?
    authorize @folder, :create?
    
    if @folder.save
      redirect_path = @folder.parent ? ged_folder_path(@folder.parent) : ged_space_path(@space)
      render json: { success: true, message: 'Dossier créé avec succès', redirect_url: redirect_path }
    else
      render json: { success: false, errors: @folder.errors.full_messages }
    end
  end

  def upload_document
    @document = Document.new(document_params)
    @document.uploaded_by = current_user
    authorize @document, :create?
    
    if @document.save
      redirect_path = @document.folder ? ged_folder_path(@document.folder) : ged_space_path(@document.space)
      render json: { 
        success: true, 
        message: 'Document uploadé avec succès. Le traitement est en cours...',
        redirect_url: redirect_path,
        document: {
          id: @document.id,
          title: @document.title,
          processing_status: @document.processing_status,
          file_size: @document.file_size,
          content_type: @document.file.content_type
        }
      }
    else
      render json: { success: false, errors: @document.errors.full_messages }
    end
  end
  
  def document_status
    @document = Document.find(params[:id])
    authorize @document, :show?
    
    render json: {
      id: @document.id,
      processing_status: @document.processing_status,
      virus_scan_status: @document.virus_scan_status,
      preview_generated: @document.preview_generated?,
      thumbnail_generated: @document.thumbnail_generated?,
      ocr_performed: @document.ocr_performed,
      extracted_content: @document.content.present?,
      tags_count: @document.tags.count,
      metadata_count: @document.metadata.count,
      processing_error: @document.processing_error
    }
  end

  def download_document
    @document = Document.find(params[:id])
    authorize @document, :show?
    
    redirect_to rails_blob_path(@document.file, disposition: "attachment")
  end
  
  def preview_document
    @document = Document.find(params[:id])
    authorize @document, :show?
    
    if @document.preview.attached?
      redirect_to rails_blob_path(@document.preview, disposition: "inline")
    elsif @document.file.content_type.start_with?('image/')
      redirect_to rails_blob_path(@document.file, disposition: "inline")
    else
      redirect_to rails_blob_path(@document.file, disposition: "inline")
    end
  end

  # Permissions management actions
  def space_permissions
    @space = current_user.organization.spaces.find(params[:id])
    authorize @space, :update?
    @authorizations = @space.authorizations.includes(:user, :user_group, :granted_by)
    @users = current_user.organization.users
    @user_groups = current_user.organization.user_groups
  end

  def update_space_permissions
    @space = current_user.organization.spaces.find(params[:id])
    authorize @space, :update?
    
    if process_permissions_update(@space)
      redirect_to ged_space_path(@space), notice: 'Permissions mises à jour avec succès'
    else
      redirect_to ged_space_permissions_path(@space), alert: 'Erreur lors de la mise à jour des permissions'
    end
  end

  def folder_permissions
    @folder = Folder.find(params[:id])
    authorize @folder, :update?
    @authorizations = @folder.authorizations.includes(:user, :user_group, :granted_by)
    @users = current_user.organization.users
    @user_groups = current_user.organization.user_groups
  end

  def update_folder_permissions
    @folder = Folder.find(params[:id])
    authorize @folder, :update?
    
    if process_permissions_update(@folder)
      redirect_to ged_folder_path(@folder), notice: 'Permissions mises à jour avec succès'
    else
      redirect_to ged_folder_permissions_path(@folder), alert: 'Erreur lors de la mise à jour des permissions'
    end
  end

  def document_permissions
    @document = Document.find(params[:id])
    authorize @document, :update?
    @authorizations = @document.authorizations.includes(:user, :user_group, :granted_by)
    @users = current_user.organization.users
    @user_groups = current_user.organization.user_groups
  end

  def update_document_permissions
    @document = Document.find(params[:id])
    authorize @document, :update?
    
    if process_permissions_update(@document)
      redirect_to ged_document_path(@document), notice: 'Permissions mises à jour avec succès'
    else
      redirect_to ged_document_permissions_path(@document), alert: 'Erreur lors de la mise à jour des permissions'
    end
  end
  
  # Document locking actions
  def lock_document
    # authorize handled elsewhere or not needed
    
    unless @document.can_lock?(current_user)
      redirect_to ged_document_path(@document), alert: 'Vous n\'avez pas les droits pour verrouiller ce document'
      return
    end
    
    lock_params = params.permit(:lock_reason, :unlock_scheduled_at)
    scheduled_unlock = lock_params[:unlock_scheduled_at].present? ? 
                      DateTime.parse(lock_params[:unlock_scheduled_at]) : nil
    
    if @document.lock_document!(current_user, reason: lock_params[:lock_reason], scheduled_unlock: scheduled_unlock)
      redirect_to ged_document_path(@document), notice: 'Document verrouillé avec succès'
    else
      redirect_to ged_document_path(@document), alert: 'Erreur lors du verrouillage du document'
    end
  end
  
  def unlock_document
    # authorize handled elsewhere or not needed
    
    unless @document.can_unlock?(current_user)
      redirect_to ged_document_path(@document), alert: 'Vous n\'avez pas les droits pour déverrouiller ce document'
      return
    end
    
    if @document.unlock_document!(current_user)
      redirect_to ged_document_path(@document), notice: 'Document déverrouillé avec succès'
    else
      redirect_to ged_document_path(@document), alert: 'Erreur lors du déverrouillage du document'
    end
  end
  
  # Document versioning actions
  def document_versions
    @document = Document.find(params[:id])
    authorize @document, :show?
    
    @versions = @document.versions.for_documents.includes(:created_by).by_version_number
    
    respond_to do |format|
      format.json { render json: @versions }
      format.html { render partial: 'ged/partials/document_versions', locals: { document: @document, versions: @versions } }
    end
  end
  
  def create_document_version
    @document = Document.find(params[:id])
    authorize @document, :update?
    
    if @document.locked? && !@document.locked_by_user?(current_user)
      render json: { error: 'Le document est verrouillé par un autre utilisateur' }, status: :locked
      return
    end
    
    uploaded_file = params[:file]
    comment = params[:comment]
    
    if uploaded_file.blank?
      render json: { error: 'Aucun fichier fourni' }, status: :unprocessable_entity
      return
    end
    
    version = @document.create_version!(uploaded_file, current_user, comment)
    
    if version
      render json: { 
        success: true, 
        message: 'Nouvelle version créée avec succès',
        version: {
          id: version.id,
          version_number: version.version_number,
          created_at: version.created_at,
          created_by: version.created_by.full_name,
          comment: version.comment
        }
      }
    else
      render json: { error: 'Erreur lors de la création de la version' }, status: :unprocessable_entity
    end
  end
  
  def restore_document_version
    @document = Document.find(params[:id])
    authorize @document, :update?
    
    if @document.locked? && !@document.locked_by_user?(current_user)
      render json: { error: 'Le document est verrouillé par un autre utilisateur' }, status: :locked
      return
    end
    
    version_number = params[:version_number].to_i
    
    restored_version = @document.restore_version!(version_number, current_user)
    
    if restored_version
      render json: { 
        success: true, 
        message: "Document restauré à partir de la version #{version_number}",
        new_version: {
          id: restored_version.id,
          version_number: restored_version.version_number,
          created_at: restored_version.created_at
        }
      }
    else
      render json: { error: 'Version introuvable ou erreur lors de la restauration' }, status: :unprocessable_entity
    end
  end
  
  def download_document_version
    @document = Document.find(params[:id])
    authorize @document, :show?
    version_number = params[:version_number].to_i
    
    version = @document.version_at(version_number)
    
    if version
      # For now, we redirect to the current document file
      # In a full implementation, you would restore the file from version metadata
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    else
      redirect_to ged_document_path(@document), alert: 'Version introuvable'
    end
  end

  private

  def set_space
    @space = current_user.organization.spaces.find(params[:space_id] || params[:id])
    authorize @space, :show?
  end

  def set_folder
    @folder = Folder.find(params[:id])
    authorize @folder, :show?
  end

  def set_document
    @document = Document.find(params[:id])
    authorize @document, :show?
  end

  def space_params
    params.require(:space).permit(:name, :description)
  end

  def folder_params
    params.require(:folder).permit(:name, :description)
  end

  def document_params
    params.require(:document).permit(:title, :description, :file, :space_id, :folder_id)
  end

  def build_folder_breadcrumbs(folder)
    breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }]
    breadcrumbs << { name: folder.space.name, path: ged_space_path(folder.space) }
    
    folder.ancestors.each do |ancestor|
      breadcrumbs << { name: ancestor.name, path: ged_folder_path(ancestor) }
    end
    
    breadcrumbs << { name: folder.name, path: ged_folder_path(folder) }
    breadcrumbs
  end

  def build_document_breadcrumbs(document)
    breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }]
    breadcrumbs << { name: document.space.name, path: ged_space_path(document.space) }
    
    if document.folder
      document.folder.ancestors.each do |ancestor|
        breadcrumbs << { name: ancestor.name, path: ged_folder_path(ancestor) }
      end
      breadcrumbs << { name: document.folder.name, path: ged_folder_path(document.folder) }
    end
    
    breadcrumbs << { name: document.title, path: ged_document_path(document) }
    breadcrumbs
  end

  def process_permissions_update(resource)
    begin
      # Traiter les nouvelles permissions
      if params[:permissions].present?
        params[:permissions].each do |permission_data|
          next unless permission_data[:user_id].present? || permission_data[:user_group_id].present?
          
          subject = permission_data[:user_id].present? ? 
                   User.find(permission_data[:user_id]) : 
                   UserGroup.find(permission_data[:user_group_id])
          
          resource.authorize_user(subject, permission_data[:permission_level], 
                                 granted_by: current_user,
                                 comment: permission_data[:comment])
        end
      end
      
      # Traiter les révocations
      if params[:revoke_permissions].present?
        params[:revoke_permissions].each do |auth_id|
          auth = resource.authorizations.find(auth_id)
          subject = auth.user || auth.user_group
          resource.revoke_authorization(subject, auth.permission_level, 
                                       revoked_by: current_user, 
                                       comment: "Révoqué via interface")
        end
      end
      
      true
    rescue => e
      Rails.logger.error "Erreur lors de la mise à jour des permissions: #{e.message}"
      false
    end
  end
  
  # Bulk document operations
  def bulk_action
    action = params[:bulk_action]
    document_ids = params[:document_ids] || []
    
    if document_ids.empty?
      render json: { error: 'Aucun document sélectionné' }, status: :unprocessable_entity
      return
    end
    
    documents = Document.where(id: document_ids)
    # Authorization will be checked per document in perform_bulk_* methods
    
    case action
    when 'delete'
      perform_bulk_delete(documents)
    when 'move'
      perform_bulk_move(documents)
    when 'tag'
      perform_bulk_tag(documents)
    when 'untag'
      perform_bulk_untag(documents)
    when 'lock'
      perform_bulk_lock(documents)
    when 'unlock'
      perform_bulk_unlock(documents)
    when 'archive'
      perform_bulk_archive(documents)
    when 'download'
      perform_bulk_download(documents)
    when 'validate'
      perform_bulk_validate(documents)
    when 'classify'
      perform_bulk_classify(documents)
    when 'check_compliance'
      perform_bulk_compliance_check(documents)
    else
      render json: { error: 'Action inconnue' }, status: :bad_request
    end
  end
  
  def perform_bulk_delete(documents)
    deleted_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_write?(current_user)
        if document.mark_for_deletion!
          deleted_count += 1
        else
          errors << "Impossible de supprimer #{document.title}"
        end
      else
        errors << "Permission refusée pour #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{deleted_count} document(s) marqué(s) pour suppression" }
    else
      render json: { message: "#{deleted_count} document(s) marqué(s) pour suppression", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_move(documents)
    destination_folder_id = params[:destination_folder_id]
    destination_space_id = params[:destination_space_id]
    
    moved_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_write?(current_user)
        document.folder_id = destination_folder_id if destination_folder_id
        document.space_id = destination_space_id if destination_space_id
        
        if document.save
          moved_count += 1
        else
          errors << "Impossible de déplacer #{document.title}: #{document.errors.full_messages.join(', ')}"
        end
      else
        errors << "Permission refusée pour déplacer #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{moved_count} document(s) déplacé(s)" }
    else
      render json: { message: "#{moved_count} document(s) déplacé(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_tag(documents)
    tag_names = params[:tags] || []
    
    tagged_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_write?(current_user)
        tag_names.each do |tag_name|
          tag = Tag.find_or_create_by(name: tag_name.strip)
          document.tags << tag unless document.tags.include?(tag)
        end
        tagged_count += 1
      else
        errors << "Permission refusée pour étiqueter #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{tagged_count} document(s) étiqueté(s)" }
    else
      render json: { message: "#{tagged_count} document(s) étiqueté(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_untag(documents)
    tag_names = params[:tags] || []
    
    untagged_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_write?(current_user)
        tags_to_remove = document.tags.where(name: tag_names)
        document.tags.destroy(tags_to_remove)
        untagged_count += 1
      else
        errors << "Permission refusée pour retirer les étiquettes de #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "Étiquettes retirées de #{untagged_count} document(s)" }
    else
      render json: { message: "Étiquettes retirées de #{untagged_count} document(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_lock(documents)
    lock_reason = params[:lock_reason] || "Verrouillage en masse"
    locked_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_lock?(current_user)
        if document.lock_document!(current_user, reason: lock_reason)
          locked_count += 1
        else
          errors << "Impossible de verrouiller #{document.title}"
        end
      else
        errors << "Permission refusée pour verrouiller #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{locked_count} document(s) verrouillé(s)" }
    else
      render json: { message: "#{locked_count} document(s) verrouillé(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_unlock(documents)
    unlocked_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_unlock?(current_user)
        if document.unlock_document!(current_user)
          unlocked_count += 1
        else
          errors << "Impossible de déverrouiller #{document.title}"
        end
      else
        errors << "Permission refusée pour déverrouiller #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{unlocked_count} document(s) déverrouillé(s)" }
    else
      render json: { message: "#{unlocked_count} document(s) déverrouillé(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_archive(documents)
    archived_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_write?(current_user)
        if document.archive!
          archived_count += 1
        else
          errors << "Impossible d'archiver #{document.title}"
        end
      else
        errors << "Permission refusée pour archiver #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{archived_count} document(s) archivé(s)" }
    else
      render json: { message: "#{archived_count} document(s) archivé(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_download(documents)
    # Generate a zip file with all documents
    require 'zip'
    
    zip_filename = "documents_#{Time.current.to_i}.zip"
    zip_path = Rails.root.join('tmp', zip_filename)
    
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      documents.each do |document|
        if document.can_read?(current_user)
          document.file.open do |file|
            zipfile.add(document.file.filename.to_s, file.path)
          end
        end
      end
    end
    
    send_file zip_path, type: 'application/zip', filename: zip_filename, disposition: 'attachment'
    
    # Clean up the zip file after sending
    File.delete(zip_path) if File.exist?(zip_path)
  rescue => e
    render json: { error: "Erreur lors de la création de l'archive: #{e.message}" }, status: :internal_server_error
  end
  
  def perform_bulk_validate(documents)
    # Create validation requests for multiple documents
    validator_ids = params[:validator_ids] || []
    min_validations = params[:min_validations]&.to_i || 1
    
    if validator_ids.empty?
      render json: { error: 'Aucun validateur sélectionné' }, status: :unprocessable_entity
      return
    end
    
    validators = User.where(id: validator_ids)
    requested_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_request_validation?(current_user)
        validation_request = document.request_validation(
          requester: current_user,
          validators: validators,
          min_validations: min_validations
        )
        
        if validation_request.persisted?
          requested_count += 1
        else
          errors << "Impossible de demander la validation pour #{document.title}"
        end
      else
        errors << "Permission refusée pour demander la validation de #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "Validation demandée pour #{requested_count} document(s)" }
    else
      render json: { message: "Validation demandée pour #{requested_count} document(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_classify(documents)
    # Trigger AI classification for multiple documents
    classified_count = 0
    errors = []
    
    documents.each do |document|
      if document.can_write?(current_user)
        if AiClassificationService.classify_document(document)
          classified_count += 1
        else
          errors << "Impossible de classifier #{document.title}"
        end
      else
        errors << "Permission refusée pour classifier #{document.title}"
      end
    end
    
    if errors.empty?
      render json: { message: "#{classified_count} document(s) classifié(s)" }
    else
      render json: { message: "#{classified_count} document(s) classifié(s)", errors: errors }, status: :partial_content
    end
  end
  
  def perform_bulk_compliance_check(documents)
    # Check regulatory compliance for multiple documents
    results = []
    
    documents.each do |document|
      if document.can_read?(current_user)
        compliance_result = RegulatoryComplianceService.check_document_compliance(document)
        results << {
          document_id: document.id,
          document_title: document.title,
          compliant: compliance_result[:compliant],
          score: compliance_result[:score],
          violations_count: compliance_result[:violations].count
        }
      end
    end
    
    compliant_count = results.count { |r| r[:compliant] }
    non_compliant_count = results.count { |r| !r[:compliant] }
    
    render json: {
      message: "Vérification de conformité terminée",
      results: {
        total_checked: results.count,
        compliant: compliant_count,
        non_compliant: non_compliant_count,
        documents: results
      }
    }
  end
end