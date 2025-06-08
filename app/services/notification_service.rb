class NotificationService
  class << self
    def notify_validation_requested(validation_request)
      validation_request.validators.each do |validator|
        Notification.notify_user(
          validator,
          :document_validation_requested,
          "Validation demandée",
          "#{validation_request.requester.full_name} demande votre validation pour le document '#{validation_request.document.title}'",
          notifiable: validation_request,
          data: {
            document_id: validation_request.document.id,
            requester_id: validation_request.requester.id,
            min_validations: validation_request.min_validations
          }
        )
      end
    end
    
    def notify_validation_approved(validation_request)
      Notification.notify_user(
        validation_request.requester,
        :document_validation_approved,
        "Validation approuvée",
        "Votre demande de validation pour le document '#{validation_request.document.title}' a été approuvée",
        notifiable: validation_request,
        data: {
          document_id: validation_request.document.id,
          approved_count: validation_request.document_validations.approved.count,
          total_validators: validation_request.document_validations.count
        }
      )
    end
    
    def notify_validation_rejected(validation_request)
      rejecting_validation = validation_request.document_validations.rejected.last
      
      Notification.notify_user(
        validation_request.requester,
        :document_validation_rejected,
        "Validation refusée",
        "Votre demande de validation pour le document '#{validation_request.document.title}' a été refusée par #{rejecting_validation.validator.full_name}",
        notifiable: validation_request,
        data: {
          document_id: validation_request.document.id,
          rejected_by: rejecting_validation.validator.full_name,
          rejection_comment: rejecting_validation.comment
        }
      )
    end
    
    def notify_document_shared(document, shared_with_user, shared_by_user)
      Notification.notify_user(
        shared_with_user,
        :document_shared,
        "Document partagé",
        "#{shared_by_user.full_name} a partagé le document '#{document.title}' avec vous",
        notifiable: document,
        data: {
          document_id: document.id,
          shared_by: shared_by_user.full_name
        }
      )
    end
    
    def notify_authorization_granted(authorizable, user, permission_type, granted_by)
      message = "#{granted_by.full_name} vous a accordé la permission '#{permission_type}' sur #{authorizable.class.name.downcase} '#{authorizable_title(authorizable)}'"
      
      Notification.notify_user(
        user,
        :authorization_granted,
        "Permission accordée",
        message,
        notifiable: authorizable,
        data: {
          permission_type: permission_type,
          granted_by: granted_by.full_name,
          authorizable_type: authorizable.class.name,
          authorizable_id: authorizable.id
        }
      )
    end
    
    def notify_authorization_revoked(authorizable, user, permission_type, revoked_by)
      message = "#{revoked_by.full_name} a révoqué votre permission '#{permission_type}' sur #{authorizable.class.name.downcase} '#{authorizable_title(authorizable)}'"
      
      Notification.notify_user(
        user,
        :authorization_revoked,
        "Permission révoquée",
        message,
        notifiable: authorizable,
        data: {
          permission_type: permission_type,
          revoked_by: revoked_by.full_name,
          authorizable_type: authorizable.class.name,
          authorizable_id: authorizable.id
        }
      )
    end
    
    def notify_document_processing_completed(document)
      Notification.notify_user(
        document.user,
        :document_processing_completed,
        "Traitement terminé",
        "Le traitement du document '#{document.title}' est terminé",
        notifiable: document,
        data: {
          document_id: document.id,
          processing_time: document.processing_metadata&.dig('processing_time')
        }
      )
    end
    
    def notify_document_processing_failed(document, error)
      Notification.notify_user(
        document.user,
        :document_processing_failed,
        "Échec du traitement",
        "Le traitement du document '#{document.title}' a échoué: #{error}",
        notifiable: document,
        data: {
          document_id: document.id,
          error_message: error
        }
      )
    end
    
    def notify_system_announcement(users, title, message, data: {})
      users.each do |user|
        Notification.notify_user(
          user,
          :system_announcement,
          title,
          message,
          data: data
        )
      end
    end
    
    def mark_all_read_for_user(user)
      Notification.mark_all_as_read_for(user)
    end
    
    def unread_count_for_user(user)
      Notification.unread.for_user(user).count
    end
    
    def recent_notifications_for_user(user, limit: 10)
      Notification.for_user(user).recent.limit(limit)
    end
    
    private
    
    def authorizable_title(authorizable)
      if authorizable.respond_to?(:title)
        authorizable.title
      elsif authorizable.respond_to?(:name)
        authorizable.name
      else
        "##{authorizable.id}"
      end
    end
  end
end