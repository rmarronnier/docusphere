require 'rails_helper'

RSpec.describe Immo::Promo::Shared::ProgressIndicatorComponent, type: :component do
  it "renders progress bar" do
    rendered = render_inline(described_class.new(progress: 75))
    
    expect(rendered).to have_css('[style*="width: 75%"]')
  end

  it "applies status-based color" do
    rendered_on_track = render_inline(described_class.new(progress: 50, status: 'on_track'))
    rendered_at_risk = render_inline(described_class.new(progress: 50, status: 'at_risk'))
    rendered_critical = render_inline(described_class.new(progress: 50, status: 'critical'))
    
    expect(rendered_on_track).to have_css('.bg-green-600')
    expect(rendered_at_risk).to have_css('.bg-yellow-600')
    expect(rendered_critical).to have_css('.bg-red-600')
  end

  it "applies auto color based on percentage when no status" do
    rendered_low = render_inline(described_class.new(progress: 30))
    rendered_medium = render_inline(described_class.new(progress: 50))
    rendered_high = render_inline(described_class.new(progress: 90))
    
    expect(rendered_low).to have_css('.bg-red-600')
    expect(rendered_medium).to have_css('.bg-yellow-600')
    expect(rendered_high).to have_css('.bg-green-600')
  end

  it "respects manual color scheme" do
    rendered = render_inline(described_class.new(progress: 50, color_scheme: 'blue'))
    
    expect(rendered).to have_css('.bg-blue-600')
  end

  it "shows/hides label based on parameter" do
    with_label = render_inline(described_class.new(progress: 60, show_label: true))
    without_label = render_inline(described_class.new(progress: 60, show_label: false))
    
    expect(with_label).to have_text('60%')
    expect(without_label).not_to have_text('60%')
  end

  it "maps size correctly" do
    rendered_small = render_inline(described_class.new(progress: 50, size: 'small'))
    rendered_large = render_inline(described_class.new(progress: 50, size: 'large'))
    
    expect(rendered_small).to have_css('.h-1\\.5')
    expect(rendered_large).to have_css('.h-4')
  end
end