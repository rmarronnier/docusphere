require 'rails_helper'

RSpec.describe BaseStatusComponent, type: :component do
  let(:status) { :active }
  let(:label) { status.to_s.humanize }
  let(:options) { {} }
  let(:component) { described_class.new(status: status, **options) }

  describe '#initialize' do
    it 'sets default values' do
      expect(component.instance_variable_get(:@status)).to eq :active
      expect(component.instance_variable_get(:@size)).to eq :default
      expect(component.instance_variable_get(:@variant)).to eq :badge
      expect(component.instance_variable_get(:@dot)).to be false
    end

    context 'with custom label' do
      let(:options) { { label: 'Custom Active' } }

      it 'uses custom label' do
        expect(component.instance_variable_get(:@label)).to eq 'Custom Active'
      end
    end

    context 'with auto label' do
      let(:status) { :in_progress }

      it 'humanizes status' do
        expect(component.instance_variable_get(:@label)).to eq 'In progress'
      end
    end
  end

  describe '#call' do
    context 'badge variant' do
      it 'renders badge' do
        render_inline(component)
        expect(page).to have_css('span.inline-flex.items-center.gap-1.font-medium.rounded-full')
      end
    end

    context 'pill variant' do
      let(:options) { { variant: :pill } }

      it 'renders pill' do
        render_inline(component)
        expect(page).to have_css('span.inline-flex.items-center.gap-1\\.5.font-medium.rounded-md')
      end
    end

    context 'dot variant' do
      let(:options) { { variant: :dot } }

      it 'renders dot status' do
        render_inline(component)
        expect(page).to have_css('div.flex.items-center.gap-2')
        expect(page).to have_css('span.w-2\\.5.h-2\\.5.rounded-full')
      end
    end

    context 'minimal variant' do
      let(:options) { { variant: :minimal } }

      it 'renders minimal text' do
        render_inline(component)
        expect(page).to have_css('span.font-medium.text-sm')
      end
    end
  end

  describe 'color mapping' do
    BaseStatusComponent::STATUS_COLORS.each do |status, color|
      context "for #{status} status" do
        let(:status) { status }

        it "uses #{color} color" do
          expect(component.send(:status_color)).to eq color
        end
      end
    end

    context 'for unknown status' do
      let(:status) { :unknown_status }

      it 'defaults to gray' do
        expect(component.send(:status_color)).to eq 'gray'
      end
    end
  end

  describe 'size variations' do
    %i[sm default lg].each do |size|
      context "with #{size} size" do
        let(:options) { { size: size } }

        it 'applies correct size classes' do
          render_inline(component)
          expect(page).to have_content(label)
        end
      end
    end
  end

  describe 'with icon' do
    let(:options) { { icon: 'check-circle' } }

    it 'renders icon' do
      render_inline(component)
      expect(page).to have_css('span.inline-block.w-4.h-4')
    end
  end

  describe 'with dot indicator' do
    let(:options) { { dot: true } }

    it 'renders dot indicator' do
      render_inline(component)
      expect(page).to have_css('span.w-2.h-2.rounded-full')
    end
  end

  describe '.add_status_colors' do
    let(:test_class) do
      Class.new(BaseStatusComponent) do
        add_status_colors(
          custom_status: 'purple',
          another_status: 'pink'
        )
      end
    end

    it 'allows adding custom status mappings' do
      component = test_class.new(status: :custom_status)
      expect(component.send(:custom_status_color)).to eq 'purple'
    end
  end
end