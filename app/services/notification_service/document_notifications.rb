module NotificationService::DocumentNotifications
  extend ActiveSupport::Concern
  
  class_methods do
    def notify_document_validation_request(document, validator, requester)
      Notification.notify_user(
        validator,
        :document_validation_request,
        "Validation de document requise",
        "Le document '#{document.title}' nécessite votre validation",
        notifiable: document,
        data: {
          document_id: document.id,
          requester_id: requester.id,
          requester_name: requester.full_name
        }
      )
    end

    def notify_document_approved(document, owner, approved_by)
      Notification.notify_user(
        owner,
        :document_approved,
        "Document approuvé",
        "Votre document '#{document.title}' a été approuvé",
        notifiable: document,
        data: {
          document_id: document.id,
          approved_by: approved_by.full_name
        }
      )
    end

    def notify_document_rejected(document, owner, rejected_by, reason = nil)
      Notification.notify_user(
        owner,
        :document_rejected,
        "Document rejeté",
        "Votre document '#{document.title}' a été rejeté",
        notifiable: document,
        data: {
          document_id: document.id,
          rejected_by: rejected_by.full_name,
          rejection_reason: reason
        }
      )
    end

    def notify_document_shared(document:, recipient:, sender:, message: nil)
      notification_message = "#{sender.full_name} a partagé le document '#{document.title}' avec vous"
      notification_message += " : #{message}" if message.present?
      
      Notification.notify_user(
        recipient,
        :document_shared,
        "Document partagé",
        notification_message,
        notifiable: document,
        data: {
          document_id: document.id,
          shared_by_id: sender.id,
          shared_by_name: sender.full_name,
          custom_message: message
        }
      )
    end

    def notify_document_comment(document, comment_author, mentioned_users = [])
      # Notifier le propriétaire du document
      if document.uploaded_by != comment_author
        Notification.notify_user(
          document.uploaded_by,
          :document_comment,
          "Nouveau commentaire",
          "#{comment_author.full_name} a commenté votre document '#{document.title}'",
          notifiable: document,
          data: {
            document_id: document.id,
            comment_author_id: comment_author.id,
            comment_author_name: comment_author.full_name
          }
        )
      end

      # Notifier les utilisateurs mentionnés
      mentioned_users.each do |user|
        next if user == comment_author
        
        Notification.notify_user(
          user,
          :document_mention,
          "Vous avez été mentionné",
          "#{comment_author.full_name} vous a mentionné dans un commentaire sur '#{document.title}'",
          notifiable: document,
          data: {
            document_id: document.id,
            comment_author_id: comment_author.id,
            comment_author_name: comment_author.full_name
          }
        )
      end
    end

    def notify_document_version_created(document, version_creator)
      # Notifier tous les utilisateurs ayant accès au document
      users_with_access = document.users_with_access - [version_creator]
      
      users_with_access.each do |user|
        Notification.notify_user(
          user,
          :document_version_created,
          "Nouvelle version disponible",
          "Une nouvelle version du document '#{document.title}' est disponible",
          notifiable: document,
          data: {
            document_id: document.id,
            version_creator_id: version_creator.id,
            version_creator_name: version_creator.full_name,
            version_number: document.versions.count
          }
        )
      end
    end

    def notify_document_expiring(document, days_until_expiry)
      Notification.notify_user(
        document.uploaded_by,
        :document_expiring,
        "Document expire bientôt",
        "Le document '#{document.title}' expire dans #{days_until_expiry} jours",
        notifiable: document,
        data: {
          document_id: document.id,
          expiry_date: document.expiry_date,
          days_until_expiry: days_until_expiry
        }
      )
    end

    def notify_document_locked(document, locked_by)
      users_to_notify = document.recent_editors - [locked_by]
      
      users_to_notify.each do |user|
        Notification.notify_user(
          user,
          :document_locked,
          "Document verrouillé",
          "#{locked_by.full_name} a verrouillé le document '#{document.title}' pour modification",
          notifiable: document,
          data: {
            document_id: document.id,
            locked_by_id: locked_by.id,
            locked_by_name: locked_by.full_name
          }
        )
      end
    end

    def notify_document_unlocked(document, unlocked_by)
      users_to_notify = document.users_waiting_for_unlock
      
      users_to_notify.each do |user|
        Notification.notify_user(
          user,
          :document_unlocked,
          "Document déverrouillé",
          "Le document '#{document.title}' est maintenant disponible pour modification",
          notifiable: document,
          data: {
            document_id: document.id,
            unlocked_by_id: unlocked_by.id,
            unlocked_by_name: unlocked_by.full_name
          }
        )
      end
    end

    def notify_virus_detected(document)
      # Notify administrators and document owner
      admins = User.where(role: 'admin').or(User.where(role: 'super_admin'))
      users_to_notify = admins.to_a
      users_to_notify << document.uploaded_by if document.uploaded_by
      users_to_notify.uniq!
      
      users_to_notify.each do |user|
        Notification.notify_user(
          user,
          :virus_detected,
          "Virus détecté",
          "Un virus a été détecté dans le document '#{document.title}'",
          notifiable: document,
          data: {
            document_id: document.id,
            virus_scan_result: document.virus_scan_result,
            priority: 'high'
          }
        )
      end
    end
  end
end