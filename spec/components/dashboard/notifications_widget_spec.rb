require 'rails_helper'

RSpec.describe Dashboard::NotificationsWidget, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:widget_data) do
    {
      id: 3,
      type: 'notifications',
      title: 'Notifications',
      config: {},
      data: { notifications: notifications }
    }
  end
  
  context 'with notifications' do
    let(:notifications) do
      [
        {
          id: 1,
          type: 'document_shared',
          title: 'Document partagé',
          message: 'Jean Dupont a partagé "Rapport Q3" avec vous',
          created_at: 5.minutes.ago,
          urgency: 'normal',
          read: false
        },
        {
          id: 2,
          type: 'validation_required', 
          title: 'Validation requise',
          message: 'Le document "Budget 2025" nécessite votre validation',
          created_at: 1.hour.ago,
          urgency: 'high',
          read: false
        },
        {
          id: 3,
          type: 'comment_added',
          title: 'Nouveau commentaire',
          message: 'Marie Martin a commenté "Plan projet"',
          created_at: 1.day.ago,
          urgency: 'low',
          read: true
        }
      ]
    end
    
    it 'renders notification list' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Notifications')
      expect(page).to have_text('Document partagé')
      expect(page).to have_text('Validation requise')
      expect(page).to have_text('Nouveau commentaire')
    end
    
    it 'shows notification messages' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Jean Dupont a partagé "Rapport Q3" avec vous')
      expect(page).to have_text('Le document "Budget 2025" nécessite votre validation')
      expect(page).to have_text('Marie Martin a commenté "Plan projet"')
    end
    
    it 'shows notification timestamps' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('il y a 5 minutes')
      expect(page).to have_text('il y a environ une heure')
      expect(page).to have_text('il y a 1 jour')
    end
    
    it 'shows urgency indicators' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-urgency="normal"]')
      expect(page).to have_css('[data-urgency="high"]')
      expect(page).to have_css('[data-urgency="low"]')
    end
    
    it 'distinguishes unread notifications' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-read="false"]', count: 2)
      expect(page).to have_css('[data-read="true"]', count: 1)
    end
    
    it 'shows notification type icons' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-notification-type="document_shared"]')
      expect(page).to have_css('[data-notification-type="validation_required"]')
      expect(page).to have_css('[data-notification-type="comment_added"]')
    end
  end
  
  context 'without notifications' do
    let(:notifications) { [] }
    
    it 'shows empty state' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Aucune notification')
      expect(page).to have_css('.empty-state')
    end
    
    it 'shows informative message' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Vous êtes à jour')
    end
  end
  
  context 'with loading state' do
    let(:notifications) { [] }
    
    it 'shows loading skeleton' do
      render_inline(described_class.new(
        widget_data: widget_data.merge(loading: true), 
        user: user
      ))
      
      expect(page).to have_css('.loading-skeleton')
    end
  end
  
  context 'with custom limit' do
    let(:notifications) do 
      Array.new(10) do |i|
        {
          id: i + 1,
          type: 'notification',
          title: "Notification #{i + 1}",
          message: "Message #{i + 1}",
          created_at: i.hours.ago,
          urgency: 'normal',
          read: false
        }
      end
    end
    
    it 'respects the configured limit' do
      widget_data[:config][:limit] = 3
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.notification-item', count: 3)
    end
  end
  
  context 'with view all link' do
    let(:notifications) { Array.new(6) { |i| { id: i + 1, type: 'notification', title: "Notification #{i + 1}", message: "Message", created_at: 1.hour.ago, urgency: 'normal', read: false } } }
    
    it 'shows view all link when there are more notifications' do
      widget_data[:config][:limit] = 5
      widget_data[:data][:total_count] = 10
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_link('Voir toutes les notifications', href: '/notifications')
    end
  end
  
  context 'with unread count' do
    let(:notifications) do
      [
        { id: 1, type: 'notification', title: 'Unread 1', message: 'Message', created_at: 1.hour.ago, urgency: 'normal', read: false },
        { id: 2, type: 'notification', title: 'Unread 2', message: 'Message', created_at: 1.hour.ago, urgency: 'normal', read: false },
        { id: 3, type: 'notification', title: 'Read', message: 'Message', created_at: 1.hour.ago, urgency: 'normal', read: true }
      ]
    end
    
    it 'shows unread count badge' do
      widget_data[:data][:unread_count] = 2
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.unread-badge', text: '2')
    end
  end
end