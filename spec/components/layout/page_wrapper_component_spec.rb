require 'rails_helper'

RSpec.describe Layout::PageWrapperComponent, type: :component do
  let(:user) { create(:user) }
  
  before do
    # Mock the navbar component to avoid Devise issues
    allow_any_instance_of(Layout::PageWrapperComponent).to receive(:render).with(
      an_instance_of(Navigation::NavbarComponent)
    ).and_return('')
    
    # Also provide the standard helpers
    mock_component_helpers(described_class, user: user)
  end
  
  it "renders with navbar by default" do
    rendered = render_inline(described_class.new) do
      "Page content"
    end
    
    expect(rendered).to have_css('.min-h-screen.bg-gray-50')
    expect(rendered).to have_text('Page content')
    # Navbar rendering would be tested through the NavbarComponent
  end

  it "renders without navbar when specified" do
    rendered = render_inline(described_class.new(with_navbar: false)) do
      "Page content"
    end
    
    expect(rendered).to have_css('.min-h-screen.bg-gray-50')
    expect(rendered).to have_text('Page content')
  end

  it "renders with default max width" do
    rendered = render_inline(described_class.new) do
      "Content"
    end
    
    expect(rendered).to have_css('.max-w-7xl')
  end

  it "renders with custom max width" do
    rendered = render_inline(described_class.new(max_width: "3xl")) do
      "Content"
    end
    
    expect(rendered).to have_css('.max-w-3xl')
  end
end