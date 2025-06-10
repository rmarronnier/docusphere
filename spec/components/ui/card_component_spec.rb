require 'rails_helper'

RSpec.describe Ui::CardComponent, type: :component do
  it "renders basic card" do
    render_inline(described_class.new) { "Card content" }
    
    expect(page).to have_css('.card')
    expect(page).to have_content('Card content')
  end
  
  it "renders with title" do
    render_inline(described_class.new(title: "My Card"))
    
    expect(page).to have_css('.card-header')
    expect(page).to have_content('My Card')
  end
  
  it "renders with custom CSS classes" do
    render_inline(described_class.new(classes: "custom-class"))
    
    expect(page).to have_css('.card.custom-class')
  end
  
  it "renders with footer slot" do
    render_inline(described_class.new) do |card|
      card.with_footer { "Footer content" }
      "Body content"
    end
    
    expect(page).to have_css('.card-body', text: "Body content")
    expect(page).to have_css('.card-footer', text: "Footer content")
  end
  
  it "renders with actions slot" do
    render_inline(described_class.new(title: "Card with Actions")) do |card|
      card.with_actions do
        '<button>Edit</button><button>Delete</button>'.html_safe
      end
    end
    
    expect(page).to have_button('Edit')
    expect(page).to have_button('Delete')
  end
  
  it "renders collapsible card" do
    render_inline(described_class.new(title: "Collapsible", collapsible: true)) do
      "Hidden content"
    end
    
    expect(page).to have_css('.card[data-controller="collapse"]')
    expect(page).to have_css('[data-action="click->collapse#toggle"]')
    expect(page).to have_css('.card-body[data-collapse-target="content"]')
  end
  
  it "renders with variant styles" do
    render_inline(described_class.new(variant: :primary))
    
    expect(page).to have_css('.card.bg-gradient-to-br.from-primary-50')
  end
  
  describe "with complex content" do
    it "renders nested components" do
      render_inline(described_class.new(title: "User Profile")) do |card|
        card.with_subtitle { "Account Information" }
        card.with_actions do
          '<button class="btn btn-sm">Edit</button>'.html_safe
        end
        
        '<div class="user-info"><p>Name: John Doe</p><p>Email: john@example.com</p></div>'.html_safe
      end
      
      expect(page).to have_css('.card-header h3', text: "User Profile")
      expect(page).to have_css('.card-subtitle', text: "Account Information")
      expect(page).to have_css('.user-info')
      expect(page).to have_button('Edit')
    end
  end
  
  describe "loading state" do
    it "shows skeleton loader when loading" do
      render_inline(described_class.new(loading: true))
      
      expect(page).to have_css('.card.animate-pulse')
      expect(page).to have_css('.h-4.bg-gray-200.rounded')
    end
  end
  
  describe "clickable cards" do
    it "renders as clickable with link" do
      render_inline(described_class.new(href: "/documents/1", clickable: true)) do
        "Document details"
      end
      
      expect(page).to have_link(href: "/documents/1")
      expect(page).to have_css('.card.cursor-pointer')
    end
  end
end