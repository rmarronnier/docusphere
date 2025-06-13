require 'rails_helper'

RSpec.describe Ui::FlashAlertComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:default_params) { { type: 'notice', message: 'Test message' } }
  let(:params) { default_params }

  describe '#initialize' do
    it 'accepts required parameters' do
      expect { component }.not_to raise_error
    end

    context 'with all parameters' do
      let(:params) do
        {
          type: 'error',
          message: 'Error message',
          dismissible: false,
          show_icon: false,
          html_safe: true
        }
      end

      it 'initializes with all parameters' do
        expect { component }.not_to raise_error
      end
    end
  end

  describe 'flash type mapping' do
    context 'when type is notice' do
      let(:params) { { type: 'notice', message: 'Success!' } }

      it 'maps to success type' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.bg-green-50')
        expect(rendered).to have_css('.text-green-700')
      end
    end

    context 'when type is alert' do
      let(:params) { { type: 'alert', message: 'Alert!' } }

      it 'maps to error type' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.bg-red-50')
        expect(rendered).to have_css('.text-red-700')
      end
    end

    context 'when type is error' do
      let(:params) { { type: 'error', message: 'Error!' } }

      it 'maps to error type' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.bg-red-50')
        expect(rendered).to have_css('.text-red-700')
      end
    end

    context 'when type is warning' do
      let(:params) { { type: 'warning', message: 'Warning!' } }

      it 'maps to warning type' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.bg-yellow-50')
        expect(rendered).to have_css('.text-yellow-700')
      end
    end

    context 'when type is info' do
      let(:params) { { type: 'info', message: 'Info!' } }

      it 'maps to info type' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.bg-blue-50')
        expect(rendered).to have_css('.text-blue-700')
      end
    end

    context 'when type is unknown' do
      let(:params) { { type: 'custom', message: 'Custom!' } }

      it 'defaults to info type' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.bg-blue-50')
        expect(rendered).to have_css('.text-blue-700')
      end
    end
  end

  describe 'dismissible functionality' do
    context 'when dismissible is true (default)' do
      let(:params) { { type: 'notice', message: 'Dismissible message' } }

      it 'renders dismiss button' do
        rendered = render_inline(component)
        expect(rendered).to have_css('button[aria-label="Dismiss"]')
        expect(rendered).to have_css('[data-action="click->alert#dismiss"]')
      end

      it 'adds alert controller' do
        rendered = render_inline(component)
        expect(rendered).to have_css('[data-controller="alert"]')
      end

      it 'marks as turbo temporary' do
        rendered = render_inline(component)
        expect(rendered).to have_css('[data-turbo-temporary="true"]')
      end
    end

    context 'when dismissible is false' do
      let(:params) { { type: 'notice', message: 'Non-dismissible message', dismissible: false } }

      it 'does not render dismiss button' do
        rendered = render_inline(component)
        expect(rendered).not_to have_css('button[aria-label="Dismiss"]')
      end

      it 'does not add alert controller' do
        rendered = render_inline(component)
        expect(rendered).not_to have_css('[data-controller="alert"]')
      end
    end
  end

  describe 'icon display' do
    context 'when show_icon is true (default)' do
      let(:params) { { type: 'success', message: 'With icon' } }

      it 'renders the appropriate icon' do
        rendered = render_inline(component)
        expect(rendered).to have_css('svg', count: 2) # icon + dismiss button
      end
    end

    context 'when show_icon is false' do
      let(:params) { { type: 'success', message: 'Without icon', show_icon: false } }

      it 'does not render the icon' do
        rendered = render_inline(component)
        expect(rendered).to have_css('svg', count: 1) # only dismiss button
      end
    end
  end

  describe 'accessibility attributes' do
    context 'for error and warning types' do
      %w[error warning].each do |type|
        context "when type is #{type}" do
          let(:params) { { type: type, message: "#{type.capitalize} message" } }

          it 'sets aria-live to assertive' do
            rendered = render_inline(component)
            expect(rendered).to have_css('[aria-live="assertive"]')
          end
        end
      end
    end

    context 'for info and success types' do
      %w[info success notice].each do |type|
        context "when type is #{type}" do
          let(:params) { { type: type, message: "#{type.capitalize} message" } }

          it 'sets aria-live to polite' do
            rendered = render_inline(component)
            expect(rendered).to have_css('[aria-live="polite"]')
          end
        end
      end
    end

    it 'has role alert' do
      rendered = render_inline(component)
      expect(rendered).to have_css('[role="alert"]')
    end

    it 'has aria-atomic true' do
      rendered = render_inline(component)
      expect(rendered).to have_css('[aria-atomic="true"]')
    end
  end

  describe 'HTML safety' do
    let(:html_message) { '<strong>Bold message</strong>' }

    context 'when html_safe is false (default)' do
      let(:params) { { type: 'notice', message: html_message } }

      it 'escapes HTML content' do
        rendered = render_inline(component)
        expect(rendered.to_html).to include('&lt;strong&gt;')
        expect(rendered).not_to have_css('strong')
      end
    end

    context 'when html_safe is true' do
      let(:params) { { type: 'notice', message: html_message.html_safe, html_safe: true } }

      it 'renders HTML content' do
        rendered = render_inline(component)
        expect(rendered).to have_css('strong', text: 'Bold message')
      end
    end
  end

  describe 'styling' do
    it 'applies base container classes' do
      rendered = render_inline(component)
      expect(rendered).to have_css('.relative.flex.p-4.rounded-md.mb-4.border')
    end

    context 'with dismissible alert' do
      it 'adds right padding for dismiss button' do
        rendered = render_inline(component)
        expect(rendered).to have_css('.pr-12')
      end
    end

    it 'applies text size class' do
      rendered = render_inline(component)
      expect(rendered).to have_css('.text-sm')
    end
  end

  describe 'integration with Rails flash' do
    # This would typically be tested in a system test or request spec
    # but we can test the component accepts standard Rails flash types
    %w[notice alert].each do |flash_type|
      it "accepts '#{flash_type}' flash type" do
        component = described_class.new(type: flash_type, message: 'Test')
        expect { render_inline(component) }.not_to raise_error
      end
    end
  end
end