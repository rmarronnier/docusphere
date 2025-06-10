require 'rails_helper'

RSpec.describe Notifications::NotificationItemComponent, type: :component do
  let(:user) { create(:user) }
  let(:notification) { create(:notification, user: user) }
  let(:options) { {} }
  let(:component) { described_class.new(notification: notification, **options) }

  before do
    Current.user = user
  end

  describe '#render' do
    it 'renders notification content' do
      render_inline(component)
      expect(page).to have_text(notification.title)
      expect(page).to have_text(notification.message) if notification.message.present?
    end

    context 'with unread notification' do
      before { notification.update!(read_at: nil) }

      it 'applies unread styling' do
        render_inline(component)
        expect(page).to have_css('.notification-item--unread')
      end

      it 'shows unread indicator' do
        render_inline(component)
        expect(page).to have_css('.bg-blue-500')  # Unread dot indicator
        expect(page).to have_text('Non lu')
      end
    end

    context 'with read notification' do
      before { notification.update!(read_at: 1.hour.ago) }

      it 'applies read styling' do
        render_inline(component)
        expect(page).not_to have_css('.notification-item--unread')
      end

      it 'does not show unread indicator' do
        render_inline(component)
        expect(page).not_to have_text('Non lu')
      end
    end

    context 'with different notification types' do
      {
        'info' => 'system_announcement',
        'success' => 'document_validation_approved', 
        'warning' => 'budget_alert',
        'error' => 'document_processing_failed'
      }.each do |category, notification_type|
        context "#{category} notification" do
          before { notification.update!(notification_type: notification_type) }

          it "shows #{category} icon" do
            render_inline(component)
            expect(page).to have_css('svg')  # Icon is rendered as SVG
          end

          it "applies #{category} color scheme" do
            render_inline(component)
            case category
            when 'success'
              expect(page).to have_css('[class*="text-green"]')
            when 'warning'
              expect(page).to have_css('[class*="text-yellow"]')
            when 'error'
              expect(page).to have_css('[class*="text-red"]')
            else
              expect(page).to have_css('[class*="text-blue"]')
            end
          end
        end
      end
    end

    context 'with actionable notification' do
      it 'renders default action buttons' do
        render_inline(component)
        expect(page).to have_text('Marquer comme lu')  # Default action for unread notifications
      end
    end

    context 'with metadata' do
      let(:options) { { layout: :detailed } }
      
      before do
        notification.update!(
          data: {
            document_name: 'Report.pdf',
            user_name: 'John Doe'
          }
        )
      end

      it 'displays metadata in detailed layout' do
        render_inline(component)
        # The data is shown in the "Données supplémentaires" section
        expect(page).to have_text('Données supplémentaires')
      end
    end

    context 'with show_actions disabled' do
      let(:options) { { show_actions: false } }

      it 'does not render action buttons' do
        render_inline(component)
        expect(page).not_to have_css('.action-button')
      end
    end
  end

  describe 'time display' do
    context 'recent notification' do
      before { notification.update!(created_at: 5.minutes.ago) }

      it 'shows relative time' do
        render_inline(component)
        expect(page).to have_text('il y a 5 minutes')  # French time format
      end
    end

    context 'old notification' do
      before { notification.update!(created_at: 3.days.ago) }

      it 'shows formatted date' do
        render_inline(component)
        expect(page).to have_text('il y a 3 jours')  # French relative time format
      end
    end
  end

  describe 'interaction' do
    it 'is clickable when unread' do
      notification.update!(read_at: nil)
      render_inline(component)
      expect(page).to have_css('a[href*="/notifications/"]')
    end

    it 'adds notification controller' do
      render_inline(component)
      expect(page).to have_css('[data-controller="notification"]')
    end
  end

  describe 'layouts' do
    context 'compact layout' do
      let(:options) { { layout: :compact } }

      it 'applies compact styling' do
        render_inline(component)
        expect(page).to have_css('.notification-item--compact')
      end

      it 'truncates message' do
        notification.update!(message: 'A' * 100)
        render_inline(component)
        expect(page).to have_text('...')
      end
    end

    context 'detailed layout' do
      let(:options) { { layout: :detailed } }

      it 'applies detailed styling' do
        render_inline(component)
        expect(page).to have_css('.notification-item--detailed')
        expect(page).to have_css('.shadow.rounded-lg')
      end

      it 'shows full message' do
        notification.update!(message: 'A' * 100)
        render_inline(component)
        expect(page).not_to have_text('...')
      end
    end
  end
end