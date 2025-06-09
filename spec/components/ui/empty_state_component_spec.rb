require 'rails_helper'

RSpec.describe Ui::EmptyStateComponent, type: :component do
  it "renders with title only" do
    rendered = render_inline(described_class.new(title: 'No results found'))
    
    expect(rendered).to have_css('.text-center')
    expect(rendered).to have_text('No results found')
  end

  it "renders with title and description" do
    rendered = render_inline(described_class.new(
      title: 'No documents',
      description: 'Upload your first document to get started'
    ))
    
    expect(rendered).to have_text('No documents')
    expect(rendered).to have_text('Upload your first document to get started')
  end

  it "renders with custom icon" do
    rendered = render_inline(described_class.new(
      title: 'Empty',
      icon: '<path d="M10 20v-6m0 0v-6m0 6h6m-6 0H4"/>'
    ))
    
    expect(rendered).to have_css('svg')
    expect(rendered).to have_css('path[d="M10 20v-6m0 0v-6m0 6h6m-6 0H4"]')
  end

  it "renders action slot content" do
    rendered = render_inline(described_class.new(title: 'No items')) do
      '<button class="btn btn-primary">Create New</button>'.html_safe
    end
    
    expect(rendered).to have_css('button.btn.btn-primary')
    expect(rendered).to have_text('Create New')
  end

  it "renders with all options" do
    rendered = render_inline(described_class.new(
      title: 'No search results',
      description: 'Try adjusting your filters',
      icon: '<circle cx="12" cy="12" r="10"/>'
    )) do
      '<a href="#" class="link">Clear filters</a>'.html_safe
    end
    
    expect(rendered).to have_text('No search results')
    expect(rendered).to have_text('Try adjusting your filters')
    expect(rendered).to have_css('circle[cx="12"][cy="12"][r="10"]')
    expect(rendered).to have_link('Clear filters')
  end
end