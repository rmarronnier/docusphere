require 'rails_helper'

RSpec.describe NotificationService::ValidationNotifications do
  # Test the module as included in NotificationService
  let(:service) { NotificationService }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:validator) { create(:user, organization: organization) }
  let(:validator2) { create(:user, organization: organization) }
  let(:document) { create(:document, uploaded_by: user) }

  describe '#notify_validation_requested' do
    let(:validation_request) do
      request = create(:validation_request, 
        validatable: document,
        requester: user
      )
      # Créer directement les document_validations sans passer par add_validators
      # pour éviter les notifications automatiques
      request.document_validations.create!(
        validatable: document,
        validator: validator,
        status: 'pending'
      )
      request
    end

    it 'creates a notification for the validator' do
      expect {
        service.notify_validation_requested(validation_request)
      }.to change { Notification.count }.by(1)
      
      notification = Notification.last
      expect(notification.user).to eq(validator)
      expect(notification.notification_type).to eq('document_validation_requested')
    end
  end

  describe '#notify_validation_approved' do
    let(:validation_request) do
      request = create(:validation_request, 
        validatable: document,
        requester: user,
        status: 'approved'
      )
      request.document_validations.create!(
        validatable: document,
        validator: validator,
        status: 'approved'
      )
      request
    end

    it 'notifies the requester when validation is approved' do
      expect {
        service.notify_validation_approved(validation_request)
      }.to change { Notification.count }.by(1)
      
      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.notification_type).to eq('document_validation_approved')
    end
  end

  describe '#notify_validation_completed' do
    context 'when validation is approved' do
      let(:validation_request) do
        request = create(:validation_request, 
          validatable: document,
          requester: user,
          status: 'approved'
        )
        request.add_validators([validator])
        request
      end

      it 'calls notify_validation_approved' do
        expect(service).to receive(:notify_validation_approved).with(validation_request)
        service.notify_validation_completed(validation_request)
      end
    end

    context 'when validation is rejected' do
      let(:validation_request) do
        request = create(:validation_request, 
          validatable: document,
          requester: user,
          status: 'rejected'
        )
        request.add_validators([validator])
        # Create a rejected document_validation
        request.document_validations.first.update!(status: 'rejected', comment: 'Not compliant')
        request
      end
      
      it 'calls notify_validation_rejected' do
        expect(service).to receive(:notify_validation_rejected).with(validation_request)
        service.notify_validation_completed(validation_request)
      end
    end
  end

  describe '#notify_validation_reminder' do
    let(:validation_request) do
      request = create(:validation_request, 
        validatable: document,
        requester: user,
        due_date: 1.day.from_now
      )
      request.document_validations.create!(
        validatable: document,
        validator: validator,
        status: 'pending'
      )
      request
    end

    it 'sends reminder notification to pending validators' do
      # Ajouter un deuxième validator en attente
      validation_request.document_validations.create!(
        validatable: document,
        validator: validator2,
        status: 'pending'
      )
      
      # Les deux validateurs n'ont pas encore validé, donc ils devraient recevoir un rappel
      expect {
        service.notify_validation_reminder(validation_request)
      }.to change { Notification.count }.by(2)
      
      notifications = Notification.last(2)
      expect(notifications.map(&:user)).to match_array([validator, validator2])
      expect(notifications.map(&:notification_type).uniq).to eq(['document_validation_reminder'])
    end
  end
end