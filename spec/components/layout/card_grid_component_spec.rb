require 'rails_helper'

RSpec.describe Layout::CardGridComponent, type: :component do
  it "renders grid with default columns" do
    rendered = render_inline(described_class.new) do
      '<div>Card 1</div><div>Card 2</div>'.html_safe
    end
    
    expect(rendered).to have_css('.grid')
    expect(rendered).to have_css('.sm\\:grid-cols-2')
    expect(rendered).to have_css('.lg\\:grid-cols-3')
    expect(rendered).to have_css('.xl\\:grid-cols-4')
  end

  it "renders with custom columns" do
    rendered = render_inline(described_class.new(
      columns: { sm: 1, lg: 2, xl: 3 }
    )) do
      '<div>Card</div>'.html_safe
    end
    
    expect(rendered).to have_css('.sm\\:grid-cols-1')
    expect(rendered).to have_css('.lg\\:grid-cols-2')
    expect(rendered).to have_css('.xl\\:grid-cols-3')
  end

  it "renders with custom gap" do
    rendered = render_inline(described_class.new(gap: 6)) do
      '<div>Card</div>'.html_safe
    end
    
    expect(rendered).to have_css('.gap-6')
  end

  it "renders nested content" do
    rendered = render_inline(described_class.new) do
      '<div class="card">Card 1</div><div class="card">Card 2</div><div class="card">Card 3</div>'.html_safe
    end
    
    expect(rendered).to have_css('.card', count: 3)
    expect(rendered).to have_text('Card 1')
    expect(rendered).to have_text('Card 2')
    expect(rendered).to have_text('Card 3')
  end
end