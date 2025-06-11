require 'rails_helper'

RSpec.describe NotificationService::ValidationNotifications do
  let(:test_class) do
    Class.new do
      include NotificationService::ValidationNotifications
      include NotificationService::UserUtilities
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:validator) { create(:user, organization: organization) }
  let(:document) { create(:document, uploaded_by: user) }
  let(:service) { test_class.new }

  describe '#notify_validation_requested' do
    let(:validation_request) do
      create(:validation_request, 
        validatable: document,
        requested_by: user,
        validator: validator
      )
    end

    it 'creates a notification for the validator' do
      expect {
        service.notify_validation_requested(validation_request)
      }.to change { Notification.count }.by(1)
      
      notification = Notification.last
      expect(notification.user).to eq(validator)
      expect(notification.notification_type).to eq('validation_request')
      expect(notification.priority).to eq('high')
    end
  end

  describe '#notify_validation_completed' do
    let(:validation_request) do
      create(:validation_request, 
        validatable: document,
        requested_by: user,
        validator: validator,
        status: 'approved'
      )
    end

    it 'notifies the requester when validation is completed' do
      expect {
        service.notify_validation_completed(validation_request)
      }.to change { Notification.count }.by(1)
      
      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.notification_type).to eq('validation_completed')
    end

    it 'sets appropriate priority based on status' do
      validation_request.update(status: 'rejected')
      service.notify_validation_completed(validation_request)
      
      notification = Notification.last
      expect(notification.priority).to eq('high')
    end
  end

  describe '#notify_validation_reminder' do
    let(:validation_request) do
      create(:validation_request, 
        validatable: document,
        validator: validator,
        due_date: 1.day.from_now
      )
    end

    it 'sends reminder notification' do
      expect {
        service.notify_validation_reminder(validation_request)
      }.to change { Notification.count }.by(1)
      
      notification = Notification.last
      expect(notification.user).to eq(validator)
      expect(notification.priority).to eq('medium')
    end
  end
end