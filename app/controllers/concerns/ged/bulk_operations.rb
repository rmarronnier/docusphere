module Ged
  module BulkOperations
    extend ActiveSupport::Concern

    def bulk_action
      action = params[:bulk_action]
      document_ids = params[:document_ids] || []
      
      if document_ids.empty?
        render json: { error: 'Aucun document sélectionné' }, status: :unprocessable_entity
        return
      end
      
      documents = Document.where(id: document_ids)
      
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
    
    private
    
    def perform_bulk_delete(documents)
      deleted_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).destroy?
          if document.destroy
            deleted_count += 1
          else
            errors << "Impossible de supprimer #{document.title}"
          end
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(deleted_count, 'supprimé', errors)
    end
    
    def perform_bulk_move(documents)
      target_folder_id = params[:target_folder_id]
      target_space_id = params[:target_space_id]
      
      if target_folder_id.blank? && target_space_id.blank?
        render json: { error: 'Destination non spécifiée' }, status: :bad_request
        return
      end
      
      moved_count = 0
      errors = []
      
      target_folder = Folder.find(target_folder_id) if target_folder_id.present?
      target_space = Space.find(target_space_id) if target_space_id.present?
      
      documents.each do |document|
        if policy(document).update?
          if target_folder
            document.folder = target_folder
            document.space = target_folder.space
          else
            document.folder = nil
            document.space = target_space
          end
          
          if document.save
            moved_count += 1
          else
            errors << "Impossible de déplacer #{document.title}"
          end
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(moved_count, 'déplacé', errors)
    end
    
    def perform_bulk_tag(documents)
      tag_names = params[:tags] || []
      tagged_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).update?
          tag_names.each do |tag_name|
            tag = Tag.find_or_create_by(name: tag_name, organization: current_user.organization)
            document.tags << tag unless document.tags.include?(tag)
          end
          tagged_count += 1
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(tagged_count, 'taggé', errors)
    end
    
    def perform_bulk_untag(documents)
      tag_names = params[:tags] || []
      untagged_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).update?
          tags_to_remove = document.tags.where(name: tag_names)
          document.tags.delete(tags_to_remove)
          untagged_count += 1
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(untagged_count, 'détaggé', errors)
    end
    
    def perform_bulk_lock(documents)
      locked_count = 0
      errors = []
      reason = params[:reason] || "Verrouillage en masse"
      
      documents.each do |document|
        if policy(document).update?
          if !document.locked? || document.locked_by == current_user
            document.lock!(current_user, reason)
            locked_count += 1
          else
            errors << "#{document.title} déjà verrouillé par #{document.locked_by.full_name}"
          end
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(locked_count, 'verrouillé', errors)
    end
    
    def perform_bulk_unlock(documents)
      unlocked_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).update? || policy(document).force_unlock?
          if document.locked?
            document.unlock!(current_user)
            unlocked_count += 1
          else
            errors << "#{document.title} n'est pas verrouillé"
          end
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(unlocked_count, 'déverrouillé', errors)
    end
    
    def perform_bulk_archive(documents)
      archived_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).update?
          if document.update(archived_at: Time.current)
            archived_count += 1
          else
            errors << "Impossible d'archiver #{document.title}"
          end
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(archived_count, 'archivé', errors)
    end
    
    def perform_bulk_download(documents)
      if documents.count > 20
        render json: { error: 'Maximum 20 documents peuvent être téléchargés simultanément' }, status: :bad_request
        return
      end
      
      authorized_documents = documents.select { |doc| policy(doc).show? }
      
      if authorized_documents.empty?
        render json: { error: 'Aucun document autorisé pour le téléchargement' }, status: :forbidden
        return
      end
      
      # Create a zip file with all documents
      zip_path = BulkDownloadService.new(authorized_documents, current_user).generate_zip
      
      send_file zip_path, 
                filename: "documents_#{Time.current.to_i}.zip",
                type: 'application/zip',
                disposition: 'attachment'
    end
    
    def perform_bulk_validate(documents)
      validated_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).validate?
          validation_request = ValidationRequest.create!(
            validatable: document,
            requester: current_user,
            description: params[:validation_reason] || "Validation en masse"
          )
          
          if validation_request.persisted?
            validated_count += 1
            # Notify validators
            NotificationService.new.notify_validation_request(validation_request)
          else
            errors << "Impossible de créer la demande pour #{document.title}"
          end
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render_bulk_result(validated_count, 'soumis à validation', errors)
    end
    
    def perform_bulk_classify(documents)
      classified_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).update?
          DocumentAiProcessingJob.perform_later(document, force: true)
          classified_count += 1
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render json: {
        success: true,
        message: "#{classified_count} document(s) envoyé(s) pour classification IA",
        errors: errors
      }
    end
    
    def perform_bulk_compliance_check(documents)
      checked_count = 0
      errors = []
      
      documents.each do |document|
        if policy(document).show?
          RegulatoryComplianceJob.perform_later(document)
          checked_count += 1
        else
          errors << "Permission refusée pour #{document.title}"
        end
      end
      
      render json: {
        success: true,
        message: "#{checked_count} document(s) envoyé(s) pour vérification de conformité",
        errors: errors
      }
    end
    
    def render_bulk_result(count, action, errors)
      if errors.any?
        render json: {
          success: count > 0,
          message: "#{count} document(s) #{action}(s)",
          errors: errors
        }, status: count > 0 ? :ok : :unprocessable_entity
      else
        render json: {
          success: true,
          message: "#{count} document(s) #{action}(s) avec succès"
        }
      end
    end
  end
end