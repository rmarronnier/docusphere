require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:document) { create(:document, organization: organization, uploaded_by: user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:notifiable).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:notification_type) }
    it { should validate_presence_of(:title) }
  end

  describe 'enums' do
    it 'defines notification types' do
      expect(Notification.notification_types).to include(
        'document_validation_requested',
        'document_shared',
        'project_created',
        'project_task_assigned',
        'budget_exceeded',
        'risk_identified',
        'system_announcement'
      )
    end
  end

  describe 'scopes' do
    let!(:read_notification) { create(:notification, user: user, read_at: 1.hour.ago) }
    let!(:unread_notification) { create(:notification, user: user, read_at: nil) }
    let!(:urgent_notification) { create(:notification, user: user, notification_type: 'budget_exceeded') }
    let!(:today_notification) { create(:notification, user: user, created_at: Time.current) }
    let!(:old_notification) { create(:notification, user: user, created_at: 1.week.ago) }

    describe '.unread' do
      it 'returns only unread notifications' do
        expect(Notification.unread).to include(unread_notification, urgent_notification)
        expect(Notification.unread).not_to include(read_notification)
      end
    end

    describe '.read' do
      it 'returns only read notifications' do
        expect(Notification.read).to include(read_notification)
        expect(Notification.read).not_to include(unread_notification)
      end
    end

    describe '.urgent' do
      it 'returns urgent notifications' do
        expect(Notification.urgent).to include(urgent_notification)
        expect(Notification.urgent).not_to include(unread_notification)
      end
    end

    describe '.today' do
      it 'returns notifications from today' do
        expect(Notification.today).to include(today_notification)
        expect(Notification.today).not_to include(old_notification)
      end
    end

    describe '.by_category' do
      let!(:document_notification) { create(:notification, user: user, notification_type: 'document_shared') }
      let!(:project_notification) { create(:notification, user: user, notification_type: 'project_created') }

      it 'filters by document category' do
        expect(Notification.by_category('documents')).to include(document_notification)
        expect(Notification.by_category('documents')).not_to include(project_notification)
      end

      it 'filters by project category' do
        expect(Notification.by_category('projects')).to include(project_notification)
        expect(Notification.by_category('projects')).not_to include(document_notification)
      end
    end
  end

  describe 'instance methods' do
    let(:notification) { create(:notification, user: user, read_at: nil) }

    describe '#mark_as_read!' do
      it 'marks notification as read' do
        expect { notification.mark_as_read! }
          .to change { notification.read_at }.from(nil)
      end

      it 'does not update already read notification' do
        notification.update!(read_at: 1.hour.ago)
        original_time = notification.read_at
        notification.mark_as_read!
        expect(notification.read_at).to eq(original_time)
      end
    end

    describe '#read?' do
      it 'returns true when read_at is present' do
        notification.update!(read_at: Time.current)
        expect(notification.read?).to be true
      end

      it 'returns false when read_at is nil' do
        expect(notification.read?).to be false
      end
    end

    describe '#unread?' do
      it 'returns opposite of read?' do
        expect(notification.unread?).to eq(!notification.read?)
      end
    end

    describe '#urgent?' do
      it 'returns true for urgent notification types' do
        urgent_notification = create(:notification, 
                                   user: user, 
                                   notification_type: 'budget_exceeded')
        expect(urgent_notification.urgent?).to be true
      end

      it 'returns false for non-urgent notification types' do
        normal_notification = create(:notification, 
                                   user: user, 
                                   notification_type: 'document_shared')
        expect(normal_notification.urgent?).to be false
      end
    end

    describe '#category' do
      it 'returns correct category for document notifications' do
        document_notification = create(:notification, 
                                     user: user, 
                                     notification_type: 'document_shared')
        expect(document_notification.category).to eq('documents')
      end

      it 'returns correct category for project notifications' do
        project_notification = create(:notification, 
                                    user: user, 
                                    notification_type: 'project_created')
        expect(project_notification.category).to eq('projects')
      end
    end

    describe '#immo_promo_related?' do
      it 'returns true for ImmoPromo categories' do
        project_notification = create(:notification, 
                                    user: user, 
                                    notification_type: 'project_created')
        expect(project_notification.immo_promo_related?).to be true
      end

      it 'returns false for non-ImmoPromo categories' do
        document_notification = create(:notification, 
                                     user: user, 
                                     notification_type: 'document_shared')
        expect(document_notification.immo_promo_related?).to be false
      end
    end

    describe '#icon' do
      it 'returns correct icon for each notification type' do
        expect(notification.icon).to be_present
        expect(notification.icon).to be_a(String)
      end
    end

    describe '#color_class' do
      it 'returns appropriate color class' do
        expect(notification.color_class).to be_present
        expect(notification.color_class).to include('text-')
      end
    end
  end

  describe 'class methods' do
    describe '.notify_user' do
      it 'creates a notification for user' do
        expect {
          Notification.notify_user(
            user,
            'document_shared',
            'Test Title',
            'Test Message',
            notifiable: document,
            data: { key: 'value' }
          )
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.user).to eq(user)
        expect(notification.notification_type).to eq('document_shared')
        expect(notification.title).to eq('Test Title')
        expect(notification.message).to eq('Test Message')
        expect(notification.notifiable).to eq(document)
      end
    end

    describe '.mark_all_as_read_for' do
      let!(:unread1) { create(:notification, user: user, read_at: nil) }
      let!(:unread2) { create(:notification, user: user, read_at: nil) }
      let!(:other_user_notification) { create(:notification, read_at: nil) }

      it 'marks all unread notifications as read for user' do
        expect {
          Notification.mark_all_as_read_for(user)
        }.to change { user.notifications.unread.count }.from(2).to(0)

        expect(other_user_notification.reload.read_at).to be_nil
      end
    end

    describe '.notification_types_by_category' do
      it 'returns correct types for documents category' do
        types = Notification.notification_types_by_category('documents')
        expect(types).to include('document_shared', 'document_validation_requested')
      end

      it 'returns correct types for projects category' do
        types = Notification.notification_types_by_category('projects')
        expect(types).to include('project_created', 'project_task_assigned')
      end
    end

    describe '.urgent_types' do
      it 'returns urgent notification types' do
        urgent_types = Notification.urgent_types
        expect(urgent_types).to include('budget_exceeded', 'project_task_overdue')
        expect(urgent_types).not_to include('document_shared')
      end
    end

    describe '.categories' do
      it 'returns all categories' do
        categories = Notification.categories
        expect(categories).to include('documents', 'projects', 'budgets', 'risks')
      end
    end
  end

  describe '#formatted_data' do
    context 'when data is a JSON string' do
      let(:notification) { create(:notification, user: user, data: '{"key": "value"}') }

      it 'parses JSON string' do
        expect(notification.formatted_data).to eq({ 'key' => 'value' })
      end
    end

    context 'when data is a hash' do
      let(:notification) { create(:notification, user: user, data: { key: 'value' }) }

      it 'returns the hash' do
        expect(notification.formatted_data).to eq({ 'key' => 'value' })
      end
    end

    context 'when data is invalid' do
      let(:notification) { create(:notification, user: user, data: 'invalid json') }

      it 'returns empty hash' do
        expect(notification.formatted_data).to eq({})
      end
    end
  end
end