require 'rails_helper'

RSpec.describe Ui::DataGridComponent::ActionComponent, type: :component do
  let(:item) { OpenStruct.new(id: 1, name: "Test Item", status: "active", draft?: false) }
  
  describe "basic rendering" do
    it "renders inline actions by default" do
      actions = [
        { label: "View", path: "/items/1" },
        { label: "Edit", path: "/items/1/edit" }
      ]
      
      render_inline(described_class.new(item: item, actions: actions))
      
      expect(page).to have_link("View", href: "/items/1")
      expect(page).to have_link("Edit", href: "/items/1/edit")
      expect(page).to have_text(" | ") # separator
    end

    it "renders no content when no actions provided" do
      render_inline(described_class.new(item: item, actions: []))
      
      expect(page).to have_css("div.flex.items-center")
      expect(page).not_to have_link
    end
  end

  describe "action filtering" do
    it "filters actions based on condition" do
      actions = [
        { label: "Publish", path: "/items/1/publish", condition: ->(item) { item.draft? } },
        { label: "Archive", path: "/items/1/archive", condition: ->(item) { !item.draft? } }
      ]
      
      render_inline(described_class.new(item: item, actions: actions))
      
      expect(page).not_to have_link("Publish") # item is not draft
      expect(page).to have_link("Archive") # item is not draft
    end

    it "filters actions based on permissions" do
      # Mock the can? helper
      allow_any_instance_of(described_class).to receive(:helpers).and_return(
        double(can?: false)
      )
      
      actions = [
        { label: "Edit", path: "/items/1/edit", permission: :edit },
        { label: "View", path: "/items/1" } # no permission required
      ]
      
      render_inline(described_class.new(item: item, actions: actions))
      
      expect(page).not_to have_link("Edit")
      expect(page).to have_link("View")
    end
  end

  describe "dropdown style" do
    it "renders actions in dropdown menu" do
      actions = [
        { label: "View", path: "/items/1", icon: "eye" },
        { label: "Edit", path: "/items/1/edit", icon: "pencil" }
      ]
      
      render_inline(described_class.new(
        item: item,
        actions: actions,
        style: :dropdown,
        dropdown_label: "Options"
      ))
      
      expect(page).to have_css("[data-controller='dropdown']")
      expect(page).to have_button("Options")
      expect(page).to have_css("[data-dropdown-target='menu']", visible: false)
      
      # Dropdown items should have the actions
      within("[data-dropdown-target='menu']") do
        expect(page).to have_link("View")
        expect(page).to have_link("Edit")
      end
    end
  end

  describe "button style" do
    it "renders actions as buttons" do
      actions = [
        { label: "Approve", path: "/items/1/approve", style: :primary },
        { label: "Reject", path: "/items/1/reject", style: :danger }
      ]
      
      render_inline(described_class.new(
        item: item,
        actions: actions,
        style: :buttons
      ))
      
      expect(page).to have_link("Approve", class: /bg-blue-600/)
      expect(page).to have_link("Reject", class: /bg-red-600/)
    end

    it "applies different sizes" do
      actions = [{ label: "Action", path: "/items/1/action" }]
      
      # Small size
      render_inline(described_class.new(item: item, actions: actions, style: :buttons, size: :small))
      expect(page).to have_css("a.px-2.py-1.text-xs")
      
      # Medium size
      render_inline(described_class.new(item: item, actions: actions, style: :buttons, size: :medium))
      expect(page).to have_css("a.px-3.py-1\\.5.text-sm")
      
      # Large size
      render_inline(described_class.new(item: item, actions: actions, style: :buttons, size: :large))
      expect(page).to have_css("a.px-4.py-2.text-base")
    end
  end

  describe "icons" do
    it "shows icons in inline style when labels hidden" do
      actions = [
        { label: "View", path: "/items/1", icon: "eye" },
        { label: "Edit", path: "/items/1/edit", icon: "pencil" }
      ]
      
      render_inline(described_class.new(
        item: item,
        actions: actions,
        show_labels: false
      ))
      
      expect(page).to have_css("svg", count: 2)
      expect(page).not_to have_text("View")
      expect(page).not_to have_text("Edit")
    end

    it "shows both icons and labels in button style" do
      actions = [
        { label: "View", path: "/items/1", icon: "eye" }
      ]
      
      render_inline(described_class.new(
        item: item,
        actions: actions,
        style: :buttons,
        show_labels: true
      ))
      
      expect(page).to have_css("svg")
      expect(page).to have_text("View")
    end
  end

  describe "data attributes" do
    it "adds confirmation dialog" do
      actions = [
        { label: "Delete", path: "/items/1", method: :delete, confirm: "Are you sure?" }
      ]
      
      render_inline(described_class.new(item: item, actions: actions))
      
      expect(page).to have_link("Delete", href: "/items/1")
      expect(page).to have_css("a[data-turbo-confirm='Are you sure?']")
      expect(page).to have_css("a[data-turbo-method='delete']")
    end

    it "adds custom data attributes" do
      actions = [
        { 
          label: "Custom", 
          path: "#",
          data: {
            controller: "custom",
            action: "click->custom#handle",
            custom_value: "test"
          }
        }
      ]
      
      render_inline(described_class.new(item: item, actions: actions))
      
      expect(page).to have_css("a[data-controller='custom']")
      expect(page).to have_css("a[data-action='click->custom#handle']")
      expect(page).to have_css("a[data-custom-value='test']")
    end
  end

  describe "gap configuration" do
    it "applies custom gap between actions" do
      actions = [
        { label: "One", path: "#" },
        { label: "Two", path: "#" }
      ]
      
      render_inline(described_class.new(
        item: item,
        actions: actions,
        style: :buttons,
        gap: 4
      ))
      
      expect(page).to have_css("div.gap-4")
    end
  end

  describe "complex scenarios" do
    it "handles mixed action configurations" do
      actions = [
        { label: "View", path: "/items/1" },
        { label: "Edit", path: "/items/1/edit", permission: :edit },
        { label: "Publish", path: "/items/1/publish", condition: ->(i) { i.draft? } },
        { 
          label: "Delete", 
          path: "/items/1", 
          method: :delete,
          style: :danger,
          confirm: "Really delete?",
          permission: :destroy
        }
      ]
      
      # Create a mock helpers object that properly evaluates the block
      mock_helpers = double("helpers")
      allow(mock_helpers).to receive(:can?) do |permission, _item|
        permission != :destroy
      end
      
      allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
      
      render_inline(described_class.new(item: item, actions: actions))
      
      expect(page).to have_link("View")
      expect(page).to have_link("Edit")
      expect(page).not_to have_link("Publish") # condition not met
      expect(page).not_to have_link("Delete") # no permission
    end
  end
end