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

  it "renders with custom SVG icon" do
    # Since icon is now expected to be a string name for IconComponent,
    # we need to test differently or update the component to detect SVG
    rendered = render_inline(described_class.new(
      title: 'Empty',
      icon: 'folder'
    ))
    
    expect(rendered).to have_css('.h-12.w-12')
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
      icon: 'search'
    )) do
      '<a href="#" class="link">Clear filters</a>'.html_safe
    end
    
    expect(rendered).to have_text('No search results')
    expect(rendered).to have_text('Try adjusting your filters')
    expect(rendered).to have_css('.h-12.w-12')
    expect(rendered).to have_link('Clear filters')
  end

  it "renders with action button" do
    rendered = render_inline(described_class.new(
      title: 'No documents',
      action_text: 'Upload Document',
      action_onclick: "openModal('upload')"
    ))
    
    expect(rendered).to have_css('button')
    expect(rendered).to have_text('Upload Document')
    expect(rendered).to have_css('button[onclick="openModal(\'upload\')"]')
  end

  it "renders with action link" do
    rendered = render_inline(described_class.new(
      title: 'No items',
      action_text: 'Create New',
      action_href: '/items/new',
      action_classes: 'custom-btn-class'
    ))
    
    expect(rendered).to have_link('Create New', href: '/items/new')
    expect(rendered).to have_css('a.custom-btn-class')
  end

  it "renders icon using IconComponent when string provided" do
    rendered = render_inline(described_class.new(
      title: 'Empty folder',
      icon: 'folder'
    ))
    
    expect(rendered).to have_css('.h-12.w-12')
    # Should render IconComponent, not raw SVG
    expect(rendered).not_to have_css('svg path[d="folder"]')
  end
end