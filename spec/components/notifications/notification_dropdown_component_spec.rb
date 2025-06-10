require 'rails_helper'

RSpec.describe Notifications::NotificationDropdownComponent, type: :component do
  let(:user) { create(:user) }
  let(:notifications) { [] }
  let(:unread_count) { 0 }
  let(:component) { described_class.new(notifications: notifications, unread_count: unread_count) }

  before do
    Current.user = user
  end

  describe '#render' do
    context 'with no notifications' do
      it 'renders empty state' do
        render_inline(component)
        expect(page).to have_text('Aucune notification')
      end

      it 'shows zero count' do
        render_inline(component)
        expect(page).not_to have_css('.bg-red-500')
      end
    end

    context 'with notifications' do
      let(:notifications) do
        [
          create(:notification, user: user, title: 'First notification'),
          create(:notification, user: user, title: 'Second notification')
        ]
      end

      it 'renders all notifications' do
        render_inline(component)
        expect(page).to have_text('First notification')
        expect(page).to have_text('Second notification')
      end

      it 'shows dropdown trigger' do
        render_inline(component)
        expect(page).to have_css('button[data-action*="dropdown"]')
      end
    end

    context 'with unread notifications' do
      let(:unread_count) { 5 }
      let(:notifications) do
        [create(:notification, user: user, read_at: nil)]
      end

      it 'shows unread badge' do
        render_inline(component)
        expect(page).to have_css('.bg-red-500')
        expect(page).to have_text('5')
      end

      it 'applies unread styling' do
        render_inline(component)
        expect(page).to have_css('.font-semibold')
      end
    end

    context 'with many notifications' do
      let(:notifications) { create_list(:notification, 10, user: user) }

      it 'limits displayed notifications' do
        render_inline(component)
        # Should show max 5 notifications + "View all" link
        expect(page).to have_css('.notification-item', maximum: 5)
      end

      it 'shows view all link' do
        render_inline(component)
        expect(page).to have_link('Voir toutes les notifications')
      end
    end
  end

  describe 'dropdown behavior' do
    let(:notifications) { [create(:notification, user: user)] }

    it 'uses dropdown controller' do
      render_inline(component)
      expect(page).to have_css('[data-controller="dropdown"]')
    end

    it 'has toggle button' do
      render_inline(component)
      expect(page).to have_css('button[data-action="click->dropdown#toggle"]')
    end

    it 'has dropdown menu' do
      render_inline(component)
      expect(page).to have_css('[data-dropdown-target="menu"]')
    end
  end

  describe 'accessibility' do
    let(:notifications) { [create(:notification, user: user)] }

    it 'has proper ARIA attributes' do
      render_inline(component)
      expect(page).to have_css('button[aria-label*="Notifications"]')
    end

    it 'marks menu as hidden by default' do
      render_inline(component)
      expect(page).to have_css('[aria-hidden="true"]')
    end
  end
end