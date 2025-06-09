require 'rails_helper'

RSpec.describe Ui::StatusBadgeComponent, type: :component do
  it "renders with preset status" do
    rendered = render_inline(described_class.new(status: :active))
    
    expect(rendered).to have_css('.inline-flex.items-center.font-medium.rounded-full')
    expect(rendered).to have_text('Active')
    expect(rendered).to have_css('.bg-green-100.text-green-800')
  end

  it "renders with custom label" do
    rendered = render_inline(described_class.new(status: :active, label: 'Custom Label'))
    
    expect(rendered).to have_text('Custom Label')
  end

  it "renders with custom color" do
    rendered = render_inline(described_class.new(label: 'Test', color: :blue))
    
    expect(rendered).to have_css('.bg-blue-100.text-blue-800')
  end

  it "renders with different sizes" do
    rendered_small = render_inline(described_class.new(label: 'Small', size: :small))
    rendered_large = render_inline(described_class.new(label: 'Large', size: :large))
    
    expect(rendered_small).to have_css('.px-2\\.5.py-0\\.5.text-xs')
    expect(rendered_large).to have_css('.px-4.py-1\\.5.text-sm')
  end

  it "renders with dot indicator" do
    rendered = render_inline(described_class.new(label: 'With Dot', dot: true))
    
    expect(rendered).to have_css('.w-2.h-2.mr-1\\.5.rounded-full')
  end

  it "renders removable badge" do
    rendered = render_inline(described_class.new(label: 'Removable', removable: true))
    
    expect(rendered).to have_css('button[aria-label="Remove Removable"]')
    expect(rendered).to have_css('button')
  end

  it "handles unknown status gracefully" do
    rendered = render_inline(described_class.new(status: :unknown_status))
    
    expect(rendered).to have_text('Unknown status')
    expect(rendered).to have_css('.bg-gray-100.text-gray-800')
  end
end