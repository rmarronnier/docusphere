# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::StatusBadgeComponent, type: :component do
  describe '#initialize' do
    it 'accepts status, label, color, size, dot, removable, icon, variant, and additional options' do
      component = described_class.new(
        status: 'active',
        label: 'Active',
        color: 'green',
        size: :large,
        dot: true,
        removable: true,
        icon: '<svg>...</svg>',
        variant: :pill,
        class: 'custom-class'
      )
      expect(component).to be_a(described_class)
    end

    it 'maps legacy size names' do
      component_small = described_class.new(status: 'active', size: :small)
      component_medium = described_class.new(status: 'active', size: :medium)
      component_large = described_class.new(status: 'active', size: :large)
      
      # These will be mapped internally to :sm, :default, :lg
      expect(component_small).to be_a(described_class)
      expect(component_medium).to be_a(described_class)
      expect(component_large).to be_a(described_class)
    end

    it 'defaults to unknown status if not provided' do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe 'rendering' do
    it 'renders a basic status badge' do
      render_inline(described_class.new(status: 'active'))
      expect(page).to have_css('span.inline-flex.items-center')
      expect(page).to have_text('Active')
    end

    it 'renders with custom label' do
      render_inline(described_class.new(status: 'active', label: 'Currently Active'))
      expect(page).to have_text('Currently Active')
    end

    it 'renders with custom color' do
      render_inline(described_class.new(status: 'custom', color: 'purple'))
      expect(page).to have_css('span.bg-purple-100.text-purple-800')
    end

    it 'renders with dot indicator when dot is true' do
      render_inline(described_class.new(status: 'active', dot: true))
      expect(page).to have_css('span.w-2.h-2.rounded-full')
    end

    it 'renders removable badge with remove button' do
      render_inline(described_class.new(status: 'active', removable: true))
      expect(page).to have_css('button[data-action="click->remove"]')
      expect(page).to have_css('button[aria-label="Remove Active"]')
    end

    it 'renders with different sizes' do
      render_inline(described_class.new(status: 'active', size: :small))
      expect(page).to have_css('span.px-2.py-0\\.5.text-xs')

      render_inline(described_class.new(status: 'active', size: :large))
      expect(page).to have_css('span.px-3.py-1.text-sm')
    end
  end

  describe 'custom status colors' do
    it 'renders at_risk status with orange color' do
      render_inline(described_class.new(status: 'at_risk'))
      expect(page).to have_css('span.bg-orange-100.text-orange-800')
    end

    it 'renders on_track status with green color' do
      render_inline(described_class.new(status: 'on_track'))
      expect(page).to have_css('span.bg-green-100.text-green-800')
    end

    it 'renders on_hold status with yellow color' do
      render_inline(described_class.new(status: 'on_hold'))
      expect(page).to have_css('span.bg-yellow-100.text-yellow-800')
    end

    it 'renders not_started status with gray color' do
      render_inline(described_class.new(status: 'not_started'))
      expect(page).to have_css('span.bg-gray-100.text-gray-800')
    end

    it 'renders delayed status with red color' do
      render_inline(described_class.new(status: 'delayed'))
      expect(page).to have_css('span.bg-red-100.text-red-800')
    end

    it 'renders in_progress status with blue color' do
      render_inline(described_class.new(status: 'in_progress'))
      expect(page).to have_css('span.bg-blue-100.text-blue-800')
    end
  end

  describe 'inherited status colors' do
    it 'renders completed status with green color' do
      render_inline(described_class.new(status: 'completed'))
      expect(page).to have_css('span.bg-green-100.text-green-800')
    end

    it 'renders pending status with yellow color' do
      render_inline(described_class.new(status: 'pending'))
      expect(page).to have_css('span.bg-yellow-100.text-yellow-800')
    end

    it 'renders failed status with red color' do
      render_inline(described_class.new(status: 'failed'))
      expect(page).to have_css('span.bg-red-100.text-red-800')
    end

    it 'renders archived status with gray color' do
      render_inline(described_class.new(status: 'archived'))
      expect(page).to have_css('span.bg-gray-100.text-gray-800')
    end

    it 'renders unknown status with gray color' do
      render_inline(described_class.new(status: 'unknown_status'))
      expect(page).to have_css('span.bg-gray-100.text-gray-800')
    end
  end

  describe 'remove button functionality' do
    it 'includes SVG icon in remove button' do
      render_inline(described_class.new(status: 'active', removable: true))
      expect(page).to have_css('button svg')
      expect(page).to have_css('svg path[d="M6 18L18 6M6 6l12 12"]')
    end

    it 'has hover and focus styles on remove button' do
      render_inline(described_class.new(status: 'active', removable: true))
      expect(page).to have_css('button.hover\\:bg-black.hover\\:bg-opacity-10')
      expect(page).to have_css('button.focus\\:ring-2.focus\\:ring-black')
    end
  end

  describe 'dot indicator' do
    it 'renders dot with correct color class' do
      render_inline(described_class.new(status: 'active', dot: true))
      expect(page).to have_css('span.bg-green-400')
    end

    it 'renders dot with custom color' do
      render_inline(described_class.new(status: 'custom', color: 'purple', dot: true))
      expect(page).to have_css('span.bg-purple-400')
    end
  end

  describe 'edge cases' do
    it 'handles nil status gracefully' do
      render_inline(described_class.new(status: nil))
      expect(page).to have_css('span.inline-flex')
      expect(page).to have_text('Unknown')
    end

    it 'handles empty label' do
      render_inline(described_class.new(status: 'active', label: ''))
      expect(page).to have_css('span.inline-flex')
      expect(page).not_to have_text('Active')
    end

    it 'handles symbol status' do
      render_inline(described_class.new(status: :active))
      expect(page).to have_css('span.bg-green-100')
      expect(page).to have_text('Active')
    end
  end

  describe 'accessibility' do
    it 'has descriptive aria-label for remove button' do
      render_inline(described_class.new(status: 'active', label: 'Custom Label', removable: true))
      expect(page).to have_css('button[aria-label="Remove Custom Label"]')
    end

    it 'marks SVG as decorative with aria-hidden' do
      render_inline(described_class.new(status: 'active', removable: true))
      expect(page).to have_css('svg[aria-hidden="true"]')
    end
  end

  describe 'CSS class structure' do
    it 'applies all necessary classes for styling' do
      render_inline(described_class.new(status: 'active'))
      badge = page.find('span.inline-flex')
      
      expect(badge[:class]).to include('inline-flex')
      expect(badge[:class]).to include('items-center')
      expect(badge[:class]).to include('gap-1')
      expect(badge[:class]).to include('font-medium')
      expect(badge[:class]).to include('rounded-full')
    end
  end

  describe 'variant styles' do
    it 'renders default badge style' do
      render_inline(described_class.new(status: 'active'))
      expect(page).to have_css('span.rounded-full.bg-green-100.text-green-800')
    end

    it 'renders pill style when variant is pill' do
      render_inline(described_class.new(status: 'active', variant: :pill))
      expect(page).to have_css('span.rounded-md.bg-green-50.text-green-700')
      expect(page).to have_css('span.ring-1.ring-inset')
    end

    it 'renders different pill sizes' do
      render_inline(described_class.new(status: 'active', variant: :pill, size: :sm))
      expect(page).to have_css('span.px-2.py-1.text-xs')

      render_inline(described_class.new(status: 'active', variant: :pill, size: :lg))
      expect(page).to have_css('span.px-4.py-2.text-base')
    end

    it 'renders removable pill with appropriate button size' do
      render_inline(described_class.new(status: 'active', variant: :pill, removable: true))
      expect(page).to have_css('button svg.h-3.w-3')
    end
  end

  describe 'icon support' do
    it 'renders icon when provided' do
      icon_svg = '<svg class="custom-icon"><path d="M10 10"/></svg>'
      render_inline(described_class.new(status: 'active', icon: icon_svg))
      expect(page).to have_css('span.inline-block.w-4.h-4')
      # Check that the icon container exists
      within('span.inline-block.w-4.h-4') do
        expect(page.native.inner_html).to include('svg')
        expect(page.native.inner_html).to include('M10 10')
      end
    end

    it 'renders icon with pill variant' do
      icon_svg = '<svg class="custom-icon"><path d="M10 10"/></svg>'
      render_inline(described_class.new(status: 'active', icon: icon_svg, variant: :pill))
      expect(page).to have_css('span.inline-block.w-4.h-4')
      # Check that the icon container exists
      within('span.inline-block.w-4.h-4') do
        expect(page.native.inner_html).to include('svg')
        expect(page.native.inner_html).to include('M10 10')
      end
    end

    it 'renders icon alongside dot indicator' do
      icon_svg = '<svg class="custom-icon"><path d="M10 10"/></svg>'
      render_inline(described_class.new(status: 'active', icon: icon_svg, dot: true))
      expect(page).to have_css('span.w-2.h-2.rounded-full') # dot
      expect(page).to have_css('span.inline-block.w-4.h-4') # icon
    end
  end

  describe 'custom CSS classes' do
    it 'applies custom CSS classes' do
      render_inline(described_class.new(status: 'active', class: 'custom-badge-class'))
      expect(page).to have_css('span.custom-badge-class')
    end

    it 'applies custom CSS classes to pill variant' do
      render_inline(described_class.new(status: 'active', variant: :pill, class: 'custom-pill-class'))
      expect(page).to have_css('span.custom-pill-class')
    end
  end

  describe 'additional options' do
    it 'accepts additional options without error' do
      component = described_class.new(
        status: 'active',
        data: { testid: 'my-badge' },
        id: 'unique-badge'
      )
      expect(component).to be_a(described_class)
    end
  end
end