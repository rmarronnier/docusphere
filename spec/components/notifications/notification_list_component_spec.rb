require 'rails_helper'

RSpec.describe Notifications::NotificationListComponent, type: :component do
  let(:user) { create(:user) }
  let(:notifications) { [] }
  let(:options) { {} }
  let(:component) { described_class.new(notifications: notifications, **options) }

  before do
    Current.user = user
  end

  describe '#render' do
    context 'with no notifications' do
      it 'renders empty state' do
        render_inline(component)
        expect(page).to have_text('Aucune notification')
      end

      it 'shows empty state icon' do
        render_inline(component)
        expect(page).to have_css('svg')  # Icon is rendered as SVG
      end
    end

    context 'with notifications' do
      let(:notifications) do
        [
          create(:notification, user: user, title: 'First', created_at: 1.hour.ago),
          create(:notification, user: user, title: 'Second', created_at: 2.hours.ago),
          create(:notification, user: user, title: 'Third', created_at: 1.day.ago)
        ]
      end

      it 'renders all notifications' do
        render_inline(component)
        expect(page).to have_text('First')
        expect(page).to have_text('Second')
        expect(page).to have_text('Third')
      end

      it 'renders notifications in order' do
        render_inline(component)
        items = page.all('[role="listitem"]')
        expect(items[0]).to have_text('First')
        expect(items[1]).to have_text('Second')
        expect(items[2]).to have_text('Third')
      end

      it 'uses NotificationItemComponent for each item' do
        render_inline(component)
        expect(page).to have_css('[role="listitem"]', count: 3)
      end
    end

    context 'with urgent notifications' do
      let(:notifications) do
        [
          create(:notification, user: user, notification_type: 'project_task_overdue'),
          create(:notification, user: user, notification_type: 'document_shared')
        ]
      end

      it 'highlights urgent notifications' do
        render_inline(component)
        expect(page).to have_css('.bg-red-100')  # Urgent notification gets red background
      end
    end

    context 'with unread notifications' do
      let(:notifications) do
        [
          create(:notification, user: user, read_at: nil),
          create(:notification, user: user, read_at: 1.hour.ago)
        ]
      end

      it 'highlights unread notifications' do
        render_inline(component)
        expect(page).to have_css('.bg-blue-50')
      end
    end

    context 'with notifiable associations' do
      let(:document) { create(:document, space: create(:space)) }
      let(:notifications) do
        [
          create(:notification, user: user, notifiable: document),
          create(:notification, user: user, notifiable: nil)
        ]
      end

      it 'generates correct URLs for notifiable objects' do
        render_inline(component)
        expect(page).to have_css("a[href*='/ged/documents/#{document.id}']", count: 1)
      end
    end

    context 'with actions disabled' do
      let(:options) { { show_actions: false } }
      let(:notifications) { create_list(:notification, 2, user: user) }

      it 'does not show action buttons' do
        render_inline(component)
        expect(page).not_to have_css('.notification-actions')
      end
    end

  end

  describe 'notification categories' do
    let(:notifications) do
      [
        create(:notification, user: user, notification_type: 'document_shared'),
        create(:notification, user: user, notification_type: 'project_created'),
        create(:notification, user: user, notification_type: 'risk_identified')
      ]
    end

    it 'displays category badges with appropriate colors' do
      render_inline(component)
      expect(page).to have_css('.bg-blue-100.text-blue-800') # documents
      expect(page).to have_css('.bg-green-100.text-green-800') # projects
      expect(page).to have_css('.bg-red-100.text-red-800') # risks
    end
  end

  describe 'compact mode' do
    let(:options) { { compact: true } }
    let(:notifications) { create_list(:notification, 3, user: user) }

    it 'applies compact styling' do
      render_inline(component)
      expect(page).to have_css('.space-y-1')
    end

    it 'shows compact time display' do
      notification = create(:notification, user: user, created_at: Time.current)
      component = described_class.new(notifications: [notification], compact: true)
      render_inline(component)
      expect(page).to have_text(notification.created_at.strftime('%H:%M'))
    end
  end

  describe 'accessibility' do
    let(:notifications) { create_list(:notification, 3, user: user) }

    it 'has proper list structure' do
      render_inline(component)
      expect(page).to have_css('[role="list"]')
    end

    it 'uses list items' do
      render_inline(component)
      expect(page).to have_css('[role="listitem"]', count: 3)
    end

    it 'has live region for updates' do
      render_inline(component)
      expect(page).to have_css('[aria-live="polite"]')
    end
  end
end