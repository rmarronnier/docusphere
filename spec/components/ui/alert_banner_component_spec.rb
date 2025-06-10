require 'rails_helper'

RSpec.describe Ui::AlertBannerComponent, type: :component do
  let(:alerts) { [] }
  let(:options) { {} }
  let(:component) { described_class.new(alerts: alerts, **options) }

  describe '#render' do
    context 'with no alerts' do
      it 'renders nothing' do
        render_inline(component)
        expect(page).not_to have_css('div')
      end
    end

    context 'with single alert' do
      let(:alerts) { [{ title: 'Warning', message: 'This is a warning message' }] }

      it 'renders alert' do
        render_inline(component)
        expect(page).to have_text('Warning')
        expect(page).to have_text('This is a warning message')
      end

      it 'does not use grid layout' do
        render_inline(component)
        expect(page).not_to have_css('.grid')
      end
    end

    context 'with multiple alerts' do
      let(:alerts) do
        [
          { title: 'First Alert', message: 'First message' },
          { title: 'Second Alert', message: 'Second message' }
        ]
      end

      it 'renders all alerts' do
        render_inline(component)
        expect(page).to have_text('First Alert')
        expect(page).to have_text('Second Alert')
      end

      it 'uses grid layout' do
        render_inline(component)
        expect(page).to have_css('.grid.grid-cols-1.md\\:grid-cols-2')
      end
    end

    context 'with string alerts' do
      let(:alerts) { ['Simple warning message', 'Another warning'] }

      it 'renders string alerts as messages' do
        render_inline(component)
        expect(page).to have_text('Simple warning message')
        expect(page).to have_text('Another warning')
      end
    end
  end

  describe 'alert types' do
    let(:alerts) { [{ message: 'Test message' }] }

    %w[danger critical error warning info success].each do |type|
      context "with #{type} type" do
        let(:options) { { type: type } }

        it "applies #{type} styling" do
          render_inline(component)
          expect(page).to have_css('div[class*="bg-"]')
        end
      end
    end

    context 'with custom title' do
      let(:options) { { title: 'Custom Alerts Title' } }

      it 'uses custom title' do
        render_inline(component)
        expect(page).to have_text('Custom Alerts Title')
      end
    end

    context 'with custom icon' do
      let(:options) { { icon: 'bell' } }

      it 'uses custom icon' do
        render_inline(component)
        expect(page).to have_css('.h-5.w-5')
      end
    end
  end

  describe 'alert severity' do
    let(:alerts) { [{ message: 'Alert', severity: 'critical' }] }

    it 'renders severity badge' do
      render_inline(component)
      expect(page).to have_css('.bg-red-100.text-red-800')
      expect(page).to have_text('Critical')
    end

    context 'with medium severity' do
      let(:alerts) { [{ message: 'Alert', severity: 'medium' }] }

      it 'renders medium severity badge' do
        render_inline(component)
        expect(page).to have_css('.bg-yellow-100.text-yellow-800')
        expect(page).to have_text('Medium')
      end
    end

    context 'with low severity' do
      let(:alerts) { [{ message: 'Alert', severity: 'low' }] }

      it 'renders low severity badge' do
        render_inline(component)
        expect(page).to have_css('.bg-green-100.text-green-800')
        expect(page).to have_text('Low')
      end
    end
  end

  describe 'alert actions' do
    let(:alerts) do
      [{
        message: 'Alert with action',
        action: { text: 'View Details', path: '/details' }
      }]
    end

    it 'renders action link' do
      render_inline(component)
      expect(page).to have_link('View Details', href: '/details')
    end

    context 'without action text' do
      let(:alerts) do
        [{
          message: 'Alert',
          action: { path: '/details' }
        }]
      end

      it 'uses default action text' do
        render_inline(component)
        expect(page).to have_link('Voir plus', href: '/details')
      end
    end
  end

  describe 'dismissible alerts' do
    let(:alerts) { [{ message: 'Dismissible alert' }] }
    let(:options) { { dismissible: true } }

    it 'renders dismiss button' do
      render_inline(component)
      expect(page).to have_css('button[data-action="click->alert#dismiss"]')
      expect(page).to have_css('.absolute.top-4.right-4')
    end

    it 'adds alert controller' do
      render_inline(component)
      expect(page).to have_css('[data-controller="alert"]')
    end
  end

  describe 'integration with concerns' do
    it 'includes Themeable concern' do
      expect(described_class.ancestors).to include(Themeable)
    end

    it 'includes Localizable concern' do
      expect(described_class.ancestors).to include(Localizable)
    end
  end

  describe 'edge cases' do
    context 'with nil in alerts array' do
      let(:alerts) { [nil, { message: 'Valid alert' }, nil] }

      it 'filters out nil values' do
        render_inline(component)
        expect(page).to have_text('Valid alert')
        expect(page).to have_css('.bg-white', count: 1)
      end
    end

    context 'with empty alerts' do
      let(:alerts) { [{}] }

      it 'renders empty alert container' do
        render_inline(component)
        expect(page).to have_css('.bg-white')
      end
    end
  end
end