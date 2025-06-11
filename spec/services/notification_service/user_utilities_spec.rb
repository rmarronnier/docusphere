require 'rails_helper'

RSpec.describe NotificationService::UserUtilities do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { NotificationService.new }
  
  describe '#notify_user' do
    it 'creates a notification for the user' do
      expect {
        service.notify_user(user, 'Test Title', 'Test message')
      }.to change(user.notifications, :count).by(1)
    end
    
    it 'accepts optional parameters' do
      service.notify_user(user, 'Title', 'Message', 
        priority: 'high',
        notification_type: 'alert',
        metadata: { foo: 'bar' }
      )
      
      notification = user.notifications.last
      expect(notification.priority).to eq('high')
      expect(notification.notification_type).to eq('alert')
      expect(notification.metadata['foo']).to eq('bar')
    end
  end
  
  describe '#notify_users' do
    let(:users) { create_list(:user, 3, organization: organization) }
    
    it 'creates notifications for multiple users' do
      expect {
        service.notify_users(users, 'Broadcast', 'Message to all')
      }.to change(Notification, :count).by(3)
    end
    
    it 'skips inactive users' do
      users.first.update!(is_active: false)
      
      expect {
        service.notify_users(users, 'Test', 'Message')
      }.to change(Notification, :count).by(2)
    end
  end
  
  describe '#users_with_role' do
    before do
      create(:user, organization: organization, role: 'admin')
      create(:user, organization: organization, role: 'manager')
      create(:user, organization: organization, role: 'user')
    end
    
    it 'finds users by role' do
      admins = service.users_with_role('admin', organization)
      expect(admins.count).to eq(1)
      expect(admins.first.role).to eq('admin')
    end
    
    it 'returns empty array for non-existent role' do
      users = service.users_with_role('superadmin', organization)
      expect(users).to be_empty
    end
  end
  
  describe '#users_with_permission' do
    it 'finds users with specific permission' do
      authorized_users = create_list(:user, 2, organization: organization)
      authorized_users.each do |user|
        create(:authorization, user: user, resource: organization, permissions: ['manage_projects'])
      end
      
      users = service.users_with_permission('manage_projects', organization)
      expect(users.count).to eq(2)
    end
  end
  
  describe '#notification_preferences' do
    it 'respects user notification preferences' do
      user.update!(notification_preferences: { email_notifications: false })
      
      prefs = service.notification_preferences(user)
      expect(prefs[:email_notifications]).to be false
    end
    
    it 'returns default preferences when not set' do
      prefs = service.notification_preferences(user)
      expect(prefs[:email_notifications]).to be true
      expect(prefs[:in_app_notifications]).to be true
    end
  end
  
  describe '#should_notify?' do
    it 'checks if user should receive notification type' do
      user.update!(notification_preferences: { budget_alerts: false })
      
      expect(service.should_notify?(user, 'budget_alert')).to be false
      expect(service.should_notify?(user, 'task_assigned')).to be true
    end
  end
  
  describe '#mark_notifications_read' do
    before do
      create_list(:notification, 5, user: user, read_at: nil)
    end
    
    it 'marks multiple notifications as read' do
      notification_ids = user.notifications.limit(3).pluck(:id)
      
      service.mark_notifications_read(notification_ids)
      
      expect(user.notifications.unread.count).to eq(2)
    end
  end
end