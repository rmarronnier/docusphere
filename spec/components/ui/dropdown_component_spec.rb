require 'rails_helper'

RSpec.describe Ui::DropdownComponent, type: :component do
  it "renders with trigger text" do
    rendered = render_inline(described_class.new(trigger_text: 'Options')) do
      '<a href="#">Action 1</a>'.html_safe
    end
    
    expect(rendered).to have_css('button')
    expect(rendered).to have_text('Options')
    expect(rendered).to have_css('[data-controller="dropdown"]')
  end

  it "renders with trigger icon" do
    rendered = render_inline(described_class.new(trigger_icon: '<path d="M12 6v6m0 0v6m0-6h6m-6 0H4"/>')) do
      '<a href="#">Action 1</a>'.html_safe
    end
    
    expect(rendered).to have_css('svg')
    expect(rendered).to have_css('path[d="M12 6v6m0 0v6m0-6h6m-6 0H4"]')
  end

  it "renders dropdown content" do
    rendered = render_inline(described_class.new(trigger_text: 'Menu')) do
      '<a href="#edit">Edit</a><a href="#delete">Delete</a>'.html_safe
    end
    
    expect(rendered).to have_link('Edit')
    expect(rendered).to have_link('Delete')
  end

  it "positions dropdown to the right by default" do
    rendered = render_inline(described_class.new(trigger_text: 'Menu')) do
      '<a href="#">Action</a>'.html_safe
    end
    
    expect(rendered).to have_css('.right-0')
  end

  it "positions dropdown to the left when specified" do
    rendered = render_inline(described_class.new(trigger_text: 'Menu', position: 'left')) do
      '<a href="#">Action</a>'.html_safe
    end
    
    expect(rendered).to have_css('.left-0')
  end

  it "has proper data attributes for interaction" do
    rendered = render_inline(described_class.new(trigger_text: 'Menu')) do
      '<a href="#">Action</a>'.html_safe
    end
    
    expect(rendered).to have_css('[data-action="click->dropdown#toggle"]')
    expect(rendered).to have_css('[data-dropdown-target="menu"]')
  end
end