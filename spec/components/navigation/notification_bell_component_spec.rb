# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Navigation::NotificationBellComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:component) { described_class.new(user: user) }
  
  before do
    allow_any_instance_of(described_class).to receive(:helpers).and_return(double(
      ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
      immo_promo_engine: double(
        project_phase_task_path: ->(project, phase, task) { "/immo/promo/projects/#{project.id}/phases/#{phase.id}/tasks/#{task.id}" }
      ),
      mark_as_read_notification_path: ->(notification) { "/notifications/#{notification.id}/mark_as_read" },
      mark_all_as_read_notifications_path: "/notifications/mark_all_as_read",
      notifications_path: "/notifications"
    ))
  end

  describe '#initialize' do
    it 'initializes with user and max_preview' do
      expect(component).to be_a(described_class)
    end
    
    it 'loads recent notifications' do
      create_list(:notification, 7, user: user)
      component = described_class.new(user: user, max_preview: 5)
      
      expect(component.send(:notifications).count).to eq(5)
    end
    
    it 'calculates unread count' do
      create_list(:notification, 3, user: user, read_at: nil)
      create_list(:notification, 2, user: user, read_at: 1.hour.ago)
      
      component = described_class.new(user: user)
      
      expect(component.send(:unread_count)).to eq(3)
    end
  end

  describe '#notification_icon' do
    it 'returns correct icon for notification types' do
      expect(component.send(:notification_icon, double(notification_type: 'validation_request'))).to eq('clipboard-check')
      expect(component.send(:notification_icon, double(notification_type: 'document_shared'))).to eq('share')
      expect(component.send(:notification_icon, double(notification_type: 'document_locked'))).to eq('lock-closed')
      expect(component.send(:notification_icon, double(notification_type: 'comment_added'))).to eq('chat-alt')
      expect(component.send(:notification_icon, double(notification_type: 'deadline_approaching'))).to eq('clock')
      expect(component.send(:notification_icon, double(notification_type: 'compliance_alert'))).to eq('exclamation')
      expect(component.send(:notification_icon, double(notification_type: 'unknown'))).to eq('bell')
    end
  end

  describe '#notification_color' do
    it 'returns correct color for priorities' do
      expect(component.send(:notification_color, double(priority: 'urgent'))).to eq('red')
      expect(component.send(:notification_color, double(priority: 'high'))).to eq('red')
      expect(component.send(:notification_color, double(priority: 'normal'))).to eq('yellow')
      expect(component.send(:notification_color, double(priority: 'low'))).to eq('green')
      expect(component.send(:notification_color, double(priority: nil))).to eq('gray')
    end
  end

  describe '#notification_title' do
    it 'returns correct title for notification types' do
      expect(component.send(:notification_title, double(notification_type: 'validation_request'))).to eq('Validation requise')
      expect(component.send(:notification_title, double(notification_type: 'document_shared'))).to eq('Document partagé')
      expect(component.send(:notification_title, double(notification_type: 'comment_added'))).to eq('Nouveau commentaire')
      expect(component.send(:notification_title, double(notification_type: 'unknown'))).to eq('Nouvelle notification')
    end
  end

  describe '#notification_time' do
    it 'formats recent times correctly' do
      notification = double(created_at: 30.minutes.ago)
      expect(component.send(:notification_time, notification)).to include('il y a')
    end
    
    it 'formats today times correctly' do
      notification = double(created_at: 3.hours.ago)
      expect(component.send(:notification_time, notification)).to match(/\d{2}:\d{2}/)
    end
    
    it 'formats yesterday times correctly' do
      notification = double(created_at: 1.day.ago)
      expect(component.send(:notification_time, notification)).to include('Hier à')
    end
    
    it 'formats older times correctly' do
      notification = double(created_at: 5.days.ago)
      expect(component.send(:notification_time, notification)).to match(/\d{2}\/\d{2} à \d{2}:\d{2}/)
    end
  end

  describe '#notification_path' do
    it 'returns document path for document notifications' do
      document = create(:document)
      notification = double(notifiable: document, notifiable_type: 'Document')
      
      expect(component.send(:notification_path, notification)).to eq("/ged/documents/#{document.id}")
    end
    
    it 'returns document path for validation request notifications' do
      document = create(:document)
      validation_request = double(validatable: document, validatable_type: 'Document')
      notification = double(notifiable: validation_request, notifiable_type: 'ValidationRequest')
      
      expect(component.send(:notification_path, notification)).to eq("/ged/documents/#{document.id}")
    end
    
    it 'returns # for notifications without notifiable' do
      notification = double(notifiable: nil)
      
      expect(component.send(:notification_path, notification)).to eq('#')
    end
  end

  describe '#badge_text' do
    it 'returns count for numbers under 100' do
      allow(component).to receive(:unread_count).and_return(42)
      
      expect(component.send(:badge_text)).to eq('42')
    end
    
    it 'returns 99+ for numbers over 99' do
      allow(component).to receive(:unread_count).and_return(150)
      
      expect(component.send(:badge_text)).to eq('99+')
    end
  end

  describe '#badge_pulse?' do
    it 'returns true when urgent unread notifications exist' do
      create(:notification, user: user, read_at: nil, priority: 'urgent')
      
      expect(component.send(:badge_pulse?)).to be_truthy
    end
    
    it 'returns false when no urgent unread notifications' do
      create(:notification, user: user, read_at: nil, priority: 'normal')
      
      expect(component.send(:badge_pulse?)).to be_falsey
    end
  end

  describe 'rendering' do
    it 'renders successfully' do
      render_inline(component)
      
      expect(page).to have_css('[data-controller*="notification-bell"]')
      expect(page).to have_css('button[aria-label="Notifications"]')
    end
    
    it 'shows badge when unread notifications exist' do
      create_list(:notification, 3, user: user, read_at: nil)
      
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('span', text: '3')
    end
    
    it 'adds pulse animation for urgent notifications' do
      create(:notification, user: user, read_at: nil, priority: 'urgent')
      
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('.animate-pulse')
    end
    
    it 'renders notification list' do
      notification = create(:notification, 
        user: user,
        notification_type: 'validation_request',
        message: 'Please validate this document',
        priority: 'high',
        read_at: nil
      )
      
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Validation requise')
      expect(page).to have_text('Please validate this document')
      expect(page).to have_css('.bg-blue-50')
    end
    
    it 'shows empty state when no notifications' do
      render_inline(component)
      
      expect(page).to have_text('Aucune notification récente')
      expect(page).to have_text('Vous recevrez des notifications ici')
    end
    
    it 'renders mark all as read link when unread exist' do
      create(:notification, user: user, read_at: nil)
      
      render_inline(described_class.new(user: user))
      
      expect(page).to have_link('Tout marquer comme lu')
    end
    
    it 'renders view all link' do
      render_inline(component)
      
      expect(page).to have_link('Voir toutes les notifications', href: '/notifications')
    end
    
    it 'renders turbo frame for real-time updates' do
      render_inline(component)
      
      expect(page).to have_css("turbo-frame#notification-updates-#{user.id}")
    end
  end
end