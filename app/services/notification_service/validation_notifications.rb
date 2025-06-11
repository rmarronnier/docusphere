module NotificationService::ValidationNotifications
    extend ActiveSupport::Concern
    
    class_methods do
      def notify_validation_requested(validation_request)
        validation_request.validators.each do |validator|
          Notification.notify_user(
            validator,
            :document_validation_requested,
            "Validation demandée",
            "#{validation_request.requester.full_name} demande votre validation pour '#{validatable_title(validation_request.validatable)}'",
            notifiable: validation_request,
            data: {
              validatable_type: validation_request.validatable_type,
              validatable_id: validation_request.validatable_id,
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
          "Votre demande de validation pour '#{validatable_title(validation_request.validatable)}' a été approuvée",
          notifiable: validation_request,
          data: {
            validatable_type: validation_request.validatable_type,
            validatable_id: validation_request.validatable_id,
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
          "Votre demande de validation pour '#{validatable_title(validation_request.validatable)}' a été refusée par #{rejecting_validation.validator.full_name}",
          notifiable: validation_request,
          data: {
            validatable_type: validation_request.validatable_type,
            validatable_id: validation_request.validatable_id,
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
            shared_by_id: shared_by_user.id,
            shared_by: shared_by_user.full_name,
            access_level: "read"
          }
        )
      end

      def notify_authorization_granted(authorizable, user, permission_type, granted_by)
        authorizable_title = authorizable_title(authorizable)
        
        Notification.notify_user(
          user,
          :authorization_granted,
          "Autorisation accordée",
          "#{granted_by.full_name} vous a accordé l'accès '#{permission_type}' à #{authorizable_title}",
          notifiable: authorizable,
          data: {
            authorizable_type: authorizable.class.name,
            authorizable_id: authorizable.id,
            permission_type: permission_type,
            granted_by_id: granted_by.id
          }
        )
      end

      def notify_authorization_revoked(authorizable, user, permission_type, revoked_by)
        authorizable_title = authorizable_title(authorizable)
        
        Notification.notify_user(
          user,
          :authorization_revoked,
          "Autorisation révoquée",
          "#{revoked_by.full_name} a révoqué votre accès '#{permission_type}' à #{authorizable_title}",
          notifiable: authorizable,
          data: {
            authorizable_type: authorizable.class.name,
            authorizable_id: authorizable.id,
            permission_type: permission_type,
            revoked_by_id: revoked_by.id
          }
        )
      end

      def notify_document_processing_completed(document)
        Notification.notify_user(
          document.uploaded_by,
          :document_processing_completed,
          "Traitement terminé",
          "Le traitement du document '#{document.title}' est terminé",
          notifiable: document,
          data: {
            document_id: document.id,
            processing_status: document.processing_status
          }
        )
      end

      def notify_document_processing_failed(document, error)
        Notification.notify_user(
          document.uploaded_by,
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

      # Notifie la complétion d'une validation (approuvée ou rejetée)
      def notify_validation_completed(validation_request)
        if validation_request.approved?
          notify_validation_approved(validation_request)
        elsif validation_request.rejected?
          notify_validation_rejected(validation_request)
        end
      end

      # Envoie un rappel aux validateurs qui n'ont pas encore validé
      def notify_validation_reminder(validation_request)
        # Trouver les validateurs qui n'ont pas encore validé
        pending_validators = validation_request.pending_validators
        
        pending_validators.each do |validator|
          days_until_due = if validation_request.due_date
            ((validation_request.due_date - Time.current) / 1.day).round
          else
            nil
          end
          
          message = if days_until_due && days_until_due > 0
            "Rappel : Vous avez #{days_until_due} jours pour valider '#{validatable_title(validation_request.validatable)}'"
          else
            "Rappel : Merci de valider '#{validatable_title(validation_request.validatable)}' dès que possible"
          end
          
          Notification.notify_user(
            validator,
            :document_validation_reminder,
            "Rappel de validation",
            message,
            notifiable: validation_request,
            data: {
              validatable_type: validation_request.validatable_type,
              validatable_id: validation_request.validatable_id,
              requester_id: validation_request.requester.id,
              due_date: validation_request.due_date,
              days_until_due: days_until_due
            }
          )
        end
      end
    end
end