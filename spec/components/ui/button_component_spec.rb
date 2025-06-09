require 'rails_helper'

RSpec.describe Ui::ButtonComponent, type: :component do
  it "renders basic button" do
    render_inline(described_class.new(text: "Click me"))
    
    expect(page).to have_button("Click me")
    expect(page).to have_css('button.btn')
  end
  
  it "renders with different variants" do
    %i[primary secondary success danger warning info].each do |variant|
      render_inline(described_class.new(text: "Button", variant: variant))
      
      expect(page).to have_css("button.btn-#{variant}")
    end
  end
  
  it "renders with different sizes" do
    %i[sm md lg].each do |size|
      render_inline(described_class.new(text: "Button", size: size))
      
      expect(page).to have_css("button.btn-#{size}")
    end
  end
  
  it "renders as link when href provided" do
    render_inline(described_class.new(text: "Link Button", href: "/documents"))
    
    expect(page).to have_link("Link Button", href: "/documents")
    expect(page).to have_css('a.btn')
  end
  
  it "renders with icon" do
    rendered = render_inline(described_class.new(text: "Save", icon: :check))
    
    expect(rendered).to have_css('svg')
    expect(rendered).to have_content("Save")
  end
  
  it "renders icon-only button" do
    render_inline(described_class.new(icon: "settings", aria_label: "Settings"))
    
    expect(page).to have_css('button.btn-icon-only')
    expect(page).to have_css('[aria-label="Settings"]')
    expect(page).not_to have_content("Settings")
  end
  
  it "renders loading state" do
    render_inline(described_class.new(text: "Submit", loading: true))
    
    expect(page).to have_css('button.btn-loading[disabled]')
    expect(page).to have_css('svg.animate-spin')
    expect(page).to have_content("Submit")
  end
  
  it "renders disabled state" do
    render_inline(described_class.new(text: "Disabled", disabled: true))
    
    expect(page).to have_button("Disabled", disabled: true)
    expect(page).to have_css('button[disabled]')
  end
  
  it "renders with custom attributes" do
    render_inline(described_class.new(
      text: "Custom",
      data: { 
        controller: "clipboard",
        action: "click->clipboard#copy"
      },
      class: "custom-class"
    ))
    
    expect(page).to have_css('button.btn.custom-class')
    expect(page).to have_css('[data-controller="clipboard"]')
    expect(page).to have_css('[data-action="click->clipboard#copy"]')
  end
  
  describe "button groups" do
    it "renders in a group context" do
      render_inline(described_class.new(text: "Option 1", group: true))
      
      expect(page).to have_css('.btn-group-item')
    end
  end
  
  describe "with dropdown" do
    it "renders dropdown button" do
      render_inline(described_class.new(text: "Actions", dropdown: true)) do |button|
        button.with_dropdown_item(text: "Edit", href: "/edit")
        button.with_dropdown_item(text: "Delete", href: "/delete", method: :delete)
      end
      
      expect(page).to have_css('[data-controller="dropdown"]')
      expect(page).to have_css('[data-action="click->dropdown#toggle"]')
      expect(page).to have_css('.dropdown-menu')
      expect(page).to have_link("Edit", href: "/edit")
      expect(page).to have_link("Delete", href: "/delete")
    end
  end
  
  describe "accessibility" do
    it "has proper ARIA attributes for loading state" do
      render_inline(described_class.new(text: "Loading", loading: true))
      
      expect(page).to have_css('[aria-busy="true"]')
      expect(page).to have_css('[aria-disabled="true"]')
    end
    
    it "requires aria-label for icon-only buttons" do
      # This should raise an error or warning in development
      expect {
        render_inline(described_class.new(icon: "close"))
      }.to raise_error(ArgumentError, /aria_label is required/)
    end
  end
  
  describe "form integration" do
    it "renders submit button with form attributes" do
      render_inline(described_class.new(
        text: "Submit",
        type: "submit",
        form: "my-form",
        name: "commit"
      ))
      
      expect(page).to have_css('button[type="submit"]')
      expect(page).to have_css('button[form="my-form"]')
      expect(page).to have_css('button[name="commit"]')
    end
  end
  
  describe "tooltip support" do
    it "renders with tooltip" do
      render_inline(described_class.new(
        text: "Help",
        tooltip: "Click for more information",
        tooltip_position: "top"
      ))
      
      expect(page).to have_css('[data-tooltip="Click for more information"]')
      expect(page).to have_css('[data-tooltip-position="top"]')
    end
  end
end