require 'rails_helper'

RSpec.describe NotificationService, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:document) { create(:document, uploaded_by: user) }

  describe '.notify_validation_requested' do
    let(:validation_request) { create(:validation_request, 
                                    validators: [user, other_user],
                                    requester: other_user,
                                    validatable: document,
                                    min_validations: 2) }

    it 'creates notifications for all validators' do
      expect {
        NotificationService.notify_validation_requested(validation_request)
      }.to change(Notification, :count).by(2)
    end

    it 'creates correct notification content' do
      NotificationService.notify_validation_requested(validation_request)
      
      notification = user.notifications.last
      expect(notification.notification_type).to eq('document_validation_requested')
      expect(notification.title).to eq('Validation demandée')
      expect(notification.notifiable).to eq(validation_request)
    end
  end

  describe '.notify_document_shared' do
    it 'creates notification for shared user' do
      expect {
        NotificationService.notify_document_shared(document, user, other_user)
      }.to change { user.notifications.count }.by(1)
    end

    it 'creates correct notification' do
      NotificationService.notify_document_shared(document, user, other_user)
      
      notification = user.notifications.last
      expect(notification.notification_type).to eq('document_shared')
      expect(notification.title).to eq('Document partagé')
      expect(notification.notifiable).to eq(document)
      expect(notification.formatted_data['shared_by_name']).to eq(other_user.full_name)
    end
  end

  describe '.notify_system_announcement' do
    let(:users) { [user, other_user] }

    it 'creates notifications for all users' do
      expect {
        NotificationService.notify_system_announcement(users, 'Test Title', 'Test Message')
      }.to change(Notification, :count).by(2)
    end

    it 'creates correct notification content' do
      NotificationService.notify_system_announcement(users, 'Test Title', 'Test Message')
      
      notification = user.notifications.last
      expect(notification.notification_type).to eq('system_announcement')
      expect(notification.title).to eq('Test Title')
      expect(notification.message).to eq('Test Message')
    end
  end

  describe '.mark_all_read_for_user' do
    let!(:unread1) { create(:notification, user: user, read_at: nil) }
    let!(:unread2) { create(:notification, user: user, read_at: nil) }
    let!(:other_user_notification) { create(:notification, user: other_user, read_at: nil) }

    it 'marks all user notifications as read' do
      NotificationService.mark_all_read_for_user(user)
      
      expect(unread1.reload.read_at).to be_present
      expect(unread2.reload.read_at).to be_present
      expect(other_user_notification.reload.read_at).to be_nil
    end
  end

  describe '.unread_count_for_user' do
    let!(:unread1) { create(:notification, user: user, read_at: nil) }
    let!(:unread2) { create(:notification, user: user, read_at: nil) }
    let!(:read_notification) { create(:notification, user: user, read_at: 1.hour.ago) }

    it 'returns correct unread count' do
      expect(NotificationService.unread_count_for_user(user)).to eq(2)
    end
  end

  describe '.recent_notifications_for_user' do
    let!(:old_notification) { create(:notification, user: user, created_at: 1.week.ago) }
    let!(:recent_notification) { create(:notification, user: user, created_at: 1.hour.ago) }

    it 'returns recent notifications in correct order' do
      notifications = NotificationService.recent_notifications_for_user(user, limit: 10)
      expect(notifications.first).to eq(recent_notification)
      expect(notifications).to include(old_notification)
    end

    it 'respects limit parameter' do
      create_list(:notification, 15, user: user)
      notifications = NotificationService.recent_notifications_for_user(user, limit: 5)
      expect(notifications.count).to eq(5)
    end
  end

  describe '.urgent_notifications_for_user' do
    let!(:urgent_notification) { create(:notification, user: user, notification_type: 'budget_exceeded', read_at: nil) }
    let!(:normal_notification) { create(:notification, user: user, notification_type: 'document_shared', read_at: nil) }
    let!(:read_urgent) { create(:notification, user: user, notification_type: 'project_task_overdue', read_at: 1.hour.ago) }

    it 'returns only unread urgent notifications' do
      notifications = NotificationService.urgent_notifications_for_user(user)
      expect(notifications).to include(urgent_notification)
      expect(notifications).not_to include(normal_notification, read_urgent)
    end
  end

  describe '.mark_notification_as_read' do
    let!(:notification) { create(:notification, user: user, read_at: nil) }

    it 'marks specific notification as read' do
      result = NotificationService.mark_notification_as_read(notification.id, user)
      expect(result.read_at).to be_present
      expect(notification.reload.read_at).to be_present
    end

    it 'raises error for notification not belonging to user' do
      other_notification = create(:notification, user: other_user)
      expect {
        NotificationService.mark_notification_as_read(other_notification.id, user)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.bulk_mark_as_read' do
    let!(:notification1) { create(:notification, user: user, read_at: nil) }
    let!(:notification2) { create(:notification, user: user, read_at: nil) }
    let!(:other_notification) { create(:notification, user: other_user, read_at: nil) }

    it 'marks multiple notifications as read' do
      count = NotificationService.bulk_mark_as_read([notification1.id, notification2.id], user)
      
      expect(count).to eq(2)
      expect(notification1.reload.read_at).to be_present
      expect(notification2.reload.read_at).to be_present
    end

    it 'only affects user notifications' do
      NotificationService.bulk_mark_as_read([notification1.id, other_notification.id], user)
      
      expect(notification1.reload.read_at).to be_present
      expect(other_notification.reload.read_at).to be_nil
    end
  end

  describe '.delete_notification' do
    let!(:notification) { create(:notification, user: user) }

    it 'deletes the notification' do
      expect {
        NotificationService.delete_notification(notification.id, user)
      }.to change(Notification, :count).by(-1)
    end

    it 'raises error for notification not belonging to user' do
      other_notification = create(:notification, user: other_user)
      expect {
        NotificationService.delete_notification(other_notification.id, user)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.bulk_delete_notifications' do
    let!(:notification1) { create(:notification, user: user) }
    let!(:notification2) { create(:notification, user: user) }
    let!(:other_notification) { create(:notification, user: other_user) }

    it 'deletes multiple notifications' do
      count = NotificationService.bulk_delete_notifications([notification1.id, notification2.id], user)
      
      expect(count).to eq(2)
      expect(Notification.exists?(notification1.id)).to be false
      expect(Notification.exists?(notification2.id)).to be false
    end

    it 'only affects user notifications' do
      NotificationService.bulk_delete_notifications([notification1.id, other_notification.id], user)
      
      expect(Notification.exists?(notification1.id)).to be false
      expect(Notification.exists?(other_notification.id)).to be true
    end
  end

  describe '.notification_stats_for_user' do
    let!(:unread_urgent) { create(:notification, user: user, notification_type: 'budget_exceeded', read_at: nil, created_at: 2.days.ago) }
    let!(:read_normal) { create(:notification, user: user, notification_type: 'document_shared', read_at: 1.hour.ago, created_at: 1.day.ago) }
    let!(:today_notification) { create(:notification, user: user, created_at: Time.current.beginning_of_day + 1.hour) }

    it 'returns comprehensive stats' do
      stats = NotificationService.notification_stats_for_user(user)
      
      expect(stats[:total]).to eq(3)
      expect(stats[:unread]).to eq(2) # unread_urgent + today_notification
      expect(stats[:urgent]).to eq(1) # unread_urgent only
      expect(stats[:today]).to eq(1)
      expect(stats[:by_category]).to be_a(Hash)
    end
  end

  # ImmoPromo specific tests
  describe 'ImmoPromo notifications', skip: 'Requires real ImmoPromo models, not doubles' do
    let(:project) { double('Project', id: 1, name: 'Test Project', stakeholders: [], project_manager: nil) }
    let(:stakeholder) { double('Stakeholder', id: 1, user: user, project: project, role: 'architect') }

    describe '.notify_project_created' do
      it 'creates notifications for stakeholders' do
        allow(project).to receive(:created_by).and_return(other_user)
        allow(project).to receive(:stakeholders).and_return([stakeholder])
        
        expect {
          NotificationService.notify_project_created(project, [user])
        }.to change(Notification, :count).by(2) # created_by + additional users
      end
    end

    describe '.notify_stakeholder_assigned' do
      it 'creates notification for assigned stakeholder' do
        expect {
          NotificationService.notify_stakeholder_assigned(stakeholder, project, other_user)
        }.to change { user.notifications.count }.by(1)
        
        notification = user.notifications.last
        expect(notification.notification_type).to eq('stakeholder_assigned')
        expect(notification.notifiable).to eq(stakeholder)
      end
    end

    describe '.notify_budget_exceeded' do
      let(:budget) { double('Budget', 
                           id: 1, 
                           name: 'Construction Budget',
                           project: project) }
      let(:stakeholders) { [double('Stakeholder', user: user), double('Stakeholder', user: other_user)] }

      before do
        allow(project).to receive(:stakeholders).and_return(stakeholders)
      end

      it 'creates notifications for project stakeholders' do
        expect {
          NotificationService.notify_budget_exceeded(budget, 15000)
        }.to change(Notification, :count).by(2)
      end

      it 'creates urgent notification' do
        NotificationService.notify_budget_exceeded(budget, 15000)
        
        notification = user.notifications.last
        expect(notification.notification_type).to eq('budget_exceeded')
        expect(notification.urgent?).to be true
      end
    end
  end

  describe '.notifications_by_category_for_user' do
    let!(:document_notification) { create(:notification, user: user, notification_type: 'document_shared') }
    let!(:project_notification) { create(:notification, user: user, notification_type: 'project_created') }

    it 'filters notifications by category' do
      documents = NotificationService.notifications_by_category_for_user(user, 'documents')
      projects = NotificationService.notifications_by_category_for_user(user, 'projects')
      
      expect(documents).to include(document_notification)
      expect(documents).not_to include(project_notification)
      
      expect(projects).to include(project_notification)
      expect(projects).not_to include(document_notification)
    end

    it 'respects limit parameter' do
      create_list(:notification, 15, user: user, notification_type: 'document_shared')
      notifications = NotificationService.notifications_by_category_for_user(user, 'documents', limit: 5)
      expect(notifications.count).to eq(5)
    end
  end
end