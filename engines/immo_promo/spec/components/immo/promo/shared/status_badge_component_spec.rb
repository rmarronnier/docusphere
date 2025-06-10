require 'rails_helper'

RSpec.describe Immo::Promo::Shared::StatusBadgeComponent, type: :component do
  it "renders with French labels" do
    rendered = render_inline(described_class.new(status: :in_progress))
    
    expect(rendered).to have_text('En cours')
    expect(rendered).to have_css('.bg-green-100.text-green-800')
  end

  it "renders with custom text" do
    rendered = render_inline(described_class.new(status: :active, custom_text: 'Texte personnalisé'))
    
    expect(rendered).to have_text('Texte personnalisé')
  end

  it "maps size correctly" do
    rendered_small = render_inline(described_class.new(status: :active, size: 'small'))
    rendered_large = render_inline(described_class.new(status: :active, size: 'large'))
    
    # The parent component maps 'small' to :sm which uses different classes
    expect(rendered_small).to have_css('.px-2.py-0\\.5.text-xs')
    expect(rendered_large).to have_css('.px-3.py-1.text-sm')
  end

  it "supports extra classes" do
    rendered = render_inline(described_class.new(status: :active, extra_classes: 'ml-2'))
    
    expect(rendered).to have_css('.ml-2')
  end

  it "renders ImmoPromo-specific statuses" do
    # Test project statuses
    expect(render_inline(described_class.new(status: :planning))).to have_text('En planification')
    expect(render_inline(described_class.new(status: :on_hold))).to have_text('En pause')
    
    # Test permit statuses
    expect(render_inline(described_class.new(status: :submitted))).to have_text('Soumis')
    expect(render_inline(described_class.new(status: :approved))).to have_text('Approuvé')
    
    # Test financial statuses
    expect(render_inline(described_class.new(status: :over_budget))).to have_text('Dépassement')
  end
end