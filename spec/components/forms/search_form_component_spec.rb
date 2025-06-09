require 'rails_helper'

RSpec.describe Forms::SearchFormComponent, type: :component do
  before do
    mock_component_helpers(described_class)
  end
  
  it "renders search form with default settings" do
    rendered = render_inline(described_class.new(url: '/search'))
    
    expect(rendered).to have_css('form[action="/search"][method="get"]')
    expect(rendered).to have_css('input[type="text"][name="search"][placeholder="Rechercher..."]')
    expect(rendered).to have_css('input[type="submit"]')
  end

  it "renders with custom placeholder" do
    rendered = render_inline(described_class.new(
      url: '/search',
      placeholder: 'Search users...'
    ))
    
    expect(rendered).to have_css('input[placeholder="Search users..."]')
  end

  it "renders with initial value" do
    rendered = render_inline(described_class.new(
      url: '/search',
      value: 'test query'
    ))
    
    expect(rendered).to have_css('input[value="test query"]')
  end

  it "renders with custom param name" do
    rendered = render_inline(described_class.new(
      url: '/search',
      param_name: :q
    ))
    
    expect(rendered).to have_css('input[name="q"]')
  end

  it "renders with custom submit text" do
    rendered = render_inline(described_class.new(
      url: '/search',
      submit_text: 'Go'
    ))
    
    expect(rendered).to have_css('input[type="submit"]')
    expect(rendered).to have_css('input[value="Go"]')
  end

  it "supports POST method" do
    rendered = render_inline(described_class.new(
      url: '/search',
      method: :post
    ))
    
    expect(rendered).to have_css('form[method="post"]')
  end

  it "has search icon in form" do
    rendered = render_inline(described_class.new(url: '/search'))
    
    expect(rendered).to have_css('svg')
  end
end