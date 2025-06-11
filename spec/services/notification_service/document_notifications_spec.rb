require 'rails_helper'

RSpec.describe NotificationService::DocumentNotifications do
  # Test the module as included in NotificationService
  let(:service) { NotificationService }
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:document) { create(:document, uploaded_by: user, title: 'Test Document') }

  describe '#notify_document_validation_request' do
    it 'creates a notification for validation request' do
      expect(Notification).to receive(:notify_user).with(
        other_user,
        :document_validation_request,
        "Validation de document requise",
        "Le document 'Test Document' nécessite votre validation",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            requester_id: user.id,
            requester_name: user.full_name
          )
        )
      )
      
      service.notify_document_validation_request(document, other_user, user)
    end
  end

  describe '#notify_document_approved' do
    it 'creates a notification for document approval' do
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_approved,
        "Document approuvé",
        "Votre document 'Test Document' a été approuvé",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            approved_by: other_user.full_name
          )
        )
      )
      
      service.notify_document_approved(document, user, other_user)
    end
  end

  describe '#notify_document_rejected' do
    it 'creates a notification for document rejection with reason' do
      reason = "Missing required information"
      
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_rejected,
        "Document rejeté",
        "Votre document 'Test Document' a été rejeté",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            rejected_by: other_user.full_name,
            rejection_reason: reason
          )
        )
      )
      
      service.notify_document_rejected(document, user, other_user, reason)
    end
  end

  describe '#notify_document_shared' do
    it 'creates a notification when document is shared' do
      expect(Notification).to receive(:notify_user).with(
        other_user,
        :document_shared,
        "Document partagé",
        "#{user.full_name} a partagé le document 'Test Document' avec vous",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            shared_by_id: user.id,
            shared_by_name: user.full_name
          )
        )
      )
      
      service.notify_document_shared(document, other_user, user)
    end
  end

  describe '#notify_document_comment' do
    let(:mentioned_user) { create(:user, organization: organization) }
    
    it 'notifies document owner when someone comments' do
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_comment,
        "Nouveau commentaire",
        "#{other_user.full_name} a commenté votre document 'Test Document'",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            comment_author_id: other_user.id,
            comment_author_name: other_user.full_name
          )
        )
      )
      
      service.notify_document_comment(document, other_user, [])
    end
    
    it 'notifies mentioned users' do
      expect(Notification).to receive(:notify_user).with(
        user,
        any_args
      )
      
      expect(Notification).to receive(:notify_user).with(
        mentioned_user,
        :document_mention,
        "Vous avez été mentionné",
        "#{other_user.full_name} vous a mentionné dans un commentaire sur 'Test Document'",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            comment_author_id: other_user.id,
            comment_author_name: other_user.full_name
          )
        )
      )
      
      service.notify_document_comment(document, other_user, [mentioned_user])
    end
    
    it 'does not notify the comment author' do
      expect(Notification).not_to receive(:notify_user).with(
        other_user,
        any_args
      )
      
      document.update(uploaded_by: other_user)
      service.notify_document_comment(document, other_user, [other_user])
    end
  end

  describe '#notify_document_version_created' do
    it 'notifies users with access about new version' do
      allow(document).to receive(:users_with_access).and_return([user, other_user])
      allow(document).to receive_message_chain(:versions, :count).and_return(2)
      
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_version_created,
        "Nouvelle version disponible",
        "Une nouvelle version du document 'Test Document' est disponible",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            version_creator_id: other_user.id,
            version_creator_name: other_user.full_name,
            version_number: 2
          )
        )
      )
      
      service.notify_document_version_created(document, other_user)
    end
  end

  describe '#notify_document_expiring' do
    it 'notifies document owner about expiring document' do
      allow(document).to receive(:expiry_date).and_return(7.days.from_now)
      
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_expiring,
        "Document expire bientôt",
        "Le document 'Test Document' expire dans 7 jours",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            expiry_date: document.expiry_date,
            days_until_expiry: 7
          )
        )
      )
      
      service.notify_document_expiring(document, 7)
    end
  end

  describe '#notify_document_locked' do
    it 'notifies recent editors when document is locked' do
      allow(document).to receive(:recent_editors).and_return([user, other_user])
      
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_locked,
        "Document verrouillé",
        "#{other_user.full_name} a verrouillé le document 'Test Document' pour modification",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            locked_by_id: other_user.id,
            locked_by_name: other_user.full_name
          )
        )
      )
      
      service.notify_document_locked(document, other_user)
    end
  end

  describe '#notify_document_unlocked' do
    it 'notifies users waiting for unlock' do
      allow(document).to receive(:users_waiting_for_unlock).and_return([user])
      
      expect(Notification).to receive(:notify_user).with(
        user,
        :document_unlocked,
        "Document déverrouillé",
        "Le document 'Test Document' est maintenant disponible pour modification",
        hash_including(
          notifiable: document,
          data: hash_including(
            document_id: document.id,
            unlocked_by_id: other_user.id,
            unlocked_by_name: other_user.full_name
          )
        )
      )
      
      service.notify_document_unlocked(document, other_user)
    end
  end
end