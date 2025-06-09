require 'rails_helper'

RSpec.describe Ui::ProgressBarComponent, type: :component do
  it "renders progress bar with percentage" do
    rendered = render_inline(described_class.new(value: 75))
    
    expect(rendered).to have_css('.bg-gray-200.rounded-full.overflow-hidden')
    expect(rendered).to have_css('[style*="width: 75%"]')
  end

  it "calculates percentage from value and max" do
    rendered = render_inline(described_class.new(value: 30, max: 60))
    
    expect(rendered).to have_css('[style*="width: 50%"]')
  end

  it "shows label when enabled" do
    rendered = render_inline(described_class.new(value: 60, show_label: true))
    
    expect(rendered).to have_text('60%')
  end

  it "hides label when disabled" do
    rendered = render_inline(described_class.new(value: 60, show_label: false))
    
    expect(rendered).not_to have_text('60%')
  end

  it "renders with different sizes" do
    rendered_small = render_inline(described_class.new(value: 50, size: :small))
    rendered_large = render_inline(described_class.new(value: 50, size: :large))
    
    expect(rendered_small).to have_css('.h-1\\.5')
    expect(rendered_large).to have_css('.h-4')
  end

  it "applies auto color based on percentage" do
    rendered_low = render_inline(described_class.new(value: 20, color: :auto))
    rendered_high = render_inline(described_class.new(value: 90, color: :auto))
    
    expect(rendered_low).to have_css('.bg-red-600')
    expect(rendered_high).to have_css('.bg-green-600')
  end

  it "applies explicit color when specified" do
    rendered = render_inline(described_class.new(value: 50, color: :blue))
    
    expect(rendered).to have_css('.bg-blue-600')
  end

  it "renders with custom label text" do
    rendered = render_inline(described_class.new(value: 50, show_label: true, label_position: :top)) do
      'Custom Progress'
    end
    
    expect(rendered).to have_text('Custom Progress')
  end

  it "handles zero max value gracefully" do
    rendered = render_inline(described_class.new(value: 50, max: 0))
    
    expect(rendered).to have_css('[style*="width: 0%"]')
  end
end