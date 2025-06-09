require 'rails_helper'

RSpec.describe Layout::PageHeaderComponent, type: :component do
  it "renders with title only" do
    rendered = render_inline(described_class.new(title: 'Page Title'))
    
    expect(rendered).to have_css('h1')
    expect(rendered).to have_text('Page Title')
  end

  it "renders with title and description" do
    rendered = render_inline(described_class.new(
      title: 'Dashboard',
      description: 'Welcome to your dashboard'
    ))
    
    expect(rendered).to have_text('Dashboard')
    expect(rendered).to have_text('Welcome to your dashboard')
  end

  it "renders action slot content" do
    rendered = render_inline(described_class.new(title: 'Users')) do
      '<button class="btn btn-primary">Add User</button>'.html_safe
    end
    
    expect(rendered).to have_css('button.btn.btn-primary')
    expect(rendered).to have_text('Add User')
  end

  it "hides actions section when show_actions is false" do
    rendered = render_inline(described_class.new(title: 'Page', show_actions: false)) do
      '<button>Should not appear</button>'.html_safe
    end
    
    expect(rendered).not_to have_css('button')
    expect(rendered).not_to have_text('Should not appear')
  end
end