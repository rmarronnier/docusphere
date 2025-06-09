require 'rails_helper'

RSpec.describe UserNotificationPreference, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:notification_type) }
    it { should validate_uniqueness_of(:notification_type).scoped_to(:user_id) }
    
    it 'validates notification_type inclusion' do
      valid_types = Notification.notification_types.keys
      valid_types.each do |type|
        preference = build(:user_notification_preference, user: user, notification_type: type)
        expect(preference).to be_valid
      end
      
      invalid_preference = build(:user_notification_preference, user: user, notification_type: 'invalid_type')
      expect(invalid_preference).not_to be_valid
    end
  end

  describe 'enums' do
    it 'defines delivery methods' do
      expect(UserNotificationPreference.delivery_methods).to include(
        'in_app', 'email', 'both', 'disabled'
      )
    end

    it 'defines frequencies' do
      expect(UserNotificationPreference.frequencies).to include(
        'immediate', 'daily_digest', 'weekly_digest', 'disabled_frequency'
      )
    end
  end

  describe 'scopes' do
    let!(:enabled_preference) { create(:user_notification_preference, user: user, enabled: true) }
    let!(:disabled_preference) { create(:user_notification_preference, user: user, enabled: false) }
    let!(:email_preference) { create(:user_notification_preference, user: user, delivery_method: 'email') }
    let!(:in_app_preference) { create(:user_notification_preference, user: user, delivery_method: 'in_app') }

    describe '.enabled' do
      it 'returns only enabled preferences' do
        expect(UserNotificationPreference.enabled).to include(enabled_preference)
        expect(UserNotificationPreference.enabled).not_to include(disabled_preference)
      end
    end

    describe '.email_enabled' do
      it 'returns preferences with email delivery' do
        both_preference = create(:user_notification_preference, user: user, delivery_method: 'both')
        
        expect(UserNotificationPreference.email_enabled).to include(email_preference, both_preference)
        expect(UserNotificationPreference.email_enabled).not_to include(in_app_preference)
      end
    end

    describe '.in_app_enabled' do
      it 'returns preferences with in-app delivery' do
        both_preference = create(:user_notification_preference, user: user, delivery_method: 'both')
        
        expect(UserNotificationPreference.in_app_enabled).to include(in_app_preference, both_preference)
        expect(UserNotificationPreference.in_app_enabled).not_to include(email_preference)
      end
    end
  end

  describe 'class methods' do
    describe '.default_preferences_for_user' do
      it 'returns default preferences for all notification types' do
        defaults = UserNotificationPreference.default_preferences_for_user(user)
        
        expect(defaults.length).to eq(Notification.notification_types.count)
        expect(defaults.first).to include(:user, :notification_type, :delivery_method, :frequency, :enabled)
      end
    end

    describe '.create_default_preferences_for_user!' do
      it 'creates default preferences for user' do
        expect {
          UserNotificationPreference.create_default_preferences_for_user!(user)
        }.to change { user.user_notification_preferences.count }.to(Notification.notification_types.count)
      end

      it 'does not create duplicates if preferences exist' do
        create(:user_notification_preference, user: user)
        
        expect {
          UserNotificationPreference.create_default_preferences_for_user!(user)
        }.not_to change { user.user_notification_preferences.count }
      end
    end

    describe '.default_delivery_method_for' do
      it 'returns both for urgent notifications' do
        expect(UserNotificationPreference.default_delivery_method_for('budget_exceeded')).to eq('both')
      end

      it 'returns both for system announcements' do
        expect(UserNotificationPreference.default_delivery_method_for('system_announcement')).to eq('both')
      end

      it 'returns in_app for regular notifications' do
        expect(UserNotificationPreference.default_delivery_method_for('document_shared')).to eq('both')
      end
    end

    describe '.default_frequency_for' do
      it 'returns immediate for urgent notifications' do
        expect(UserNotificationPreference.default_frequency_for('budget_exceeded')).to eq('immediate')
      end

      it 'returns immediate for task assignments' do
        expect(UserNotificationPreference.default_frequency_for('project_task_assigned')).to eq('immediate')
      end

      it 'returns daily_digest for regular notifications' do
        expect(UserNotificationPreference.default_frequency_for('project_updated')).to eq('daily_digest')
      end
    end
  end

  describe 'instance methods' do
    let(:preference) { create(:user_notification_preference, user: user, notification_type: 'document_shared') }

    describe '#urgent_notification?' do
      it 'returns true for urgent notification types' do
        urgent_preference = create(:user_notification_preference, 
                                 user: user, 
                                 notification_type: 'budget_exceeded')
        expect(urgent_preference.urgent_notification?).to be true
      end

      it 'returns false for non-urgent notification types' do
        expect(preference.urgent_notification?).to be false
      end
    end

    describe '#category' do
      it 'returns correct category' do
        expect(preference.category).to eq('documents')
      end
    end

    describe '#should_deliver_in_app?' do
      it 'returns true when enabled and delivery method includes in_app' do
        preference.update!(enabled: true, delivery_method: 'in_app')
        expect(preference.should_deliver_in_app?).to be true
        
        preference.update!(delivery_method: 'both')
        expect(preference.should_deliver_in_app?).to be true
      end

      it 'returns false when disabled' do
        preference.update!(enabled: false, delivery_method: 'in_app')
        expect(preference.should_deliver_in_app?).to be false
      end

      it 'returns false when delivery method is email only' do
        preference.update!(enabled: true, delivery_method: 'email')
        expect(preference.should_deliver_in_app?).to be false
      end
    end

    describe '#should_deliver_email?' do
      it 'returns true when enabled and delivery method includes email' do
        preference.update!(enabled: true, delivery_method: 'email')
        expect(preference.should_deliver_email?).to be true
        
        preference.update!(delivery_method: 'both')
        expect(preference.should_deliver_email?).to be true
      end

      it 'returns false when disabled' do
        preference.update!(enabled: false, delivery_method: 'email')
        expect(preference.should_deliver_email?).to be false
      end

      it 'returns false when delivery method is in_app only' do
        preference.update!(enabled: true, delivery_method: 'in_app')
        expect(preference.should_deliver_email?).to be false
      end
    end

    describe '#should_deliver_immediately?' do
      it 'returns true for urgent notifications' do
        urgent_preference = create(:user_notification_preference, 
                                 user: user, 
                                 notification_type: 'budget_exceeded',
                                 frequency: 'daily_digest')
        expect(urgent_preference.should_deliver_immediately?).to be true
      end

      it 'returns true when frequency is immediate' do
        preference.update!(frequency: 'immediate')
        expect(preference.should_deliver_immediately?).to be true
      end

      it 'returns false for non-urgent with non-immediate frequency' do
        preference.update!(frequency: 'daily_digest')
        expect(preference.should_deliver_immediately?).to be false
      end
    end

    describe '#display_name' do
      it 'returns humanized notification type' do
        expect(preference.display_name).to eq('Document shared')
      end
    end

    describe '#description' do
      it 'returns description for notification type' do
        expect(preference.description).to include('Document shared')
      end
    end
  end
end