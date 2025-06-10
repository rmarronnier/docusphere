require 'rails_helper'

RSpec.describe Ui::StatusBadgeComponent, type: :component do
  describe 'inheritance' do
    it 'inherits from BaseStatusComponent' do
      expect(described_class.superclass).to eq BaseStatusComponent
    end
  end

  it "renders with preset status" do
    rendered = render_inline(described_class.new(status: :active))
    
    expect(rendered).to have_css('span.inline-flex.items-center')
    expect(rendered).to have_text('Active')
    expect(rendered).to have_css('[class*="bg-green"][class*="text-green"]')
  end

  it "renders with custom label" do
    rendered = render_inline(described_class.new(status: :active, label: 'Custom Label'))
    
    expect(rendered).to have_text('Custom Label')
  end

  it "renders with custom color" do
    rendered = render_inline(described_class.new(label: 'Test', color: 'blue'))
    
    expect(rendered).to have_css('[class*="bg-blue"][class*="text-blue"]')
  end

  it "renders with different sizes" do
    # Note: size mapping has changed from :small/:large to :sm/:lg
    rendered_small = render_inline(described_class.new(label: 'Small', size: :small))
    rendered_large = render_inline(described_class.new(label: 'Large', size: :large))
    
    expect(rendered_small).to have_css('[class*="text-xs"]')
    expect(rendered_large).to have_css('[class*="text-sm"]')
  end

  it "renders with dot indicator" do
    rendered = render_inline(described_class.new(label: 'With Dot', dot: true))
    
    expect(rendered).to have_css('span.w-2.h-2.rounded-full')
  end

  it "renders removable badge" do
    rendered = render_inline(described_class.new(label: 'Removable', removable: true))
    
    expect(rendered).to have_css('button[data-action="click->remove"]')
    expect(rendered).to have_css('svg.h-2.w-2')
  end

  it "handles unknown status gracefully" do
    rendered = render_inline(described_class.new(status: :unknown_status))
    
    expect(rendered).to have_text('Unknown status')
    expect(rendered).to have_css('[class*="bg-gray"][class*="text-gray"]')
  end

  describe 'custom status colors' do
    it 'supports ImmoPromo specific statuses' do
      rendered = render_inline(described_class.new(status: :at_risk))
      expect(rendered).to have_css('[class*="bg-orange"][class*="text-orange"]')
    end

    it 'supports on_track status' do
      rendered = render_inline(described_class.new(status: :on_track))
      expect(rendered).to have_css('[class*="bg-green"][class*="text-green"]')
    end
  end
end