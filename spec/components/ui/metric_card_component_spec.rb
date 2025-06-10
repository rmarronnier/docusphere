require 'rails_helper'

RSpec.describe Ui::MetricCardComponent, type: :component do
  let(:title) { 'Revenue' }
  let(:value) { 125000 }
  let(:options) { {} }
  let(:component) { described_class.new(title: title, value: value, **options) }

  describe '#render' do
    it 'renders metric card with title and value' do
      render_inline(component)
      expect(page).to have_text('Revenue')
      expect(page).to have_text('125 000')  # French formatting uses space as thousand separator
    end

    context 'with subtitle' do
      let(:options) { { subtitle: 'This month' } }

      it 'renders subtitle' do
        render_inline(component)
        expect(page).to have_text('This month')
      end
    end

    context 'with icon' do
      let(:options) { { icon: 'currency-dollar' } }

      it 'renders icon' do
        render_inline(component)
        expect(page).to have_css('.h-8.w-8')
      end
    end

    context 'without icon' do
      let(:options) { { icon: nil } }

      it 'does not render icon space' do
        render_inline(component)
        expect(page).not_to have_css('.ml-4')
      end
    end

    context 'with trend' do
      context 'upward trend' do
        let(:options) { { trend: :up, trend_value: '+12%' } }

        it 'renders upward trend' do
          render_inline(component)
          expect(page).to have_css('.text-green-600')
          expect(page).to have_text('+12%')
        end
      end

      context 'downward trend' do
        let(:options) { { trend: :down, trend_value: '-5%' } }

        it 'renders downward trend' do
          render_inline(component)
          expect(page).to have_css('.text-red-600')
          expect(page).to have_text('-5%')
        end
      end

      context 'stable trend' do
        let(:options) { { trend: :stable } }

        it 'renders stable trend' do
          render_inline(component)
          expect(page).to have_css('.text-gray-500')
        end
      end
    end
  end

  describe 'value formatting' do
    context 'with Money value' do
      let(:value) { Money.new(150000, 'EUR') }

      it 'formats as currency' do
        render_inline(component)
        expect(page).to have_text('1 500,00 € EUR')  # Actual Money format output
      end
    end

    context 'with numeric value' do
      let(:value) { 1234567 }

      it 'formats with delimiter' do
        render_inline(component)
        expect(page).to have_text('1 234 567')  # French formatting
      end
    end

    context 'with decimal value' do
      let(:value) { 123.456 }
      let(:options) { { format: :auto } }

      it 'formats with precision' do
        render_inline(component)
        expect(page).to have_text('123,46')  # French formatting uses comma as decimal separator
      end
    end

    context 'with percentage format' do
      let(:value) { 85.5 }
      let(:options) { { format: :percentage } }

      it 'formats as percentage' do
        render_inline(component)
        expect(page).to have_text('85,5%')  # French formatting
      end
    end

    context 'with string value' do
      let(:value) { 'Active' }

      it 'displays as is' do
        render_inline(component)
        expect(page).to have_text('Active')
      end
    end

    context 'with no formatting' do
      let(:value) { 12345 }
      let(:options) { { format: :none } }

      it 'displays raw value' do
        render_inline(component)
        expect(page).to have_text('12345')
      end
    end
  end

  describe 'styling options' do
    context 'with custom background color' do
      let(:options) { { bg_color: 'bg-blue-50' } }

      it 'applies custom background' do
        render_inline(component)
        expect(page).to have_css('.bg-blue-50')
      end
    end

    context 'with custom value color' do
      let(:options) { { value_color: 'text-blue-900' } }

      it 'applies custom value color' do
        render_inline(component)
        expect(page).to have_css('.text-blue-900')
      end
    end

    context 'with custom class' do
      let(:options) { { class: 'custom-metric-card' } }

      it 'applies custom class' do
        render_inline(component)
        expect(page).to have_css('.custom-metric-card')
      end
    end
  end

  describe 'integration with Themeable' do
    it 'includes Themeable concern' do
      expect(described_class.ancestors).to include(Themeable)
    end
  end
end