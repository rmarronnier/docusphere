# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::ActionDropdownComponent, type: :component do
  let(:basic_actions) do
    [
      {
        label: "Voir",
        href: "/documents/1",
        icon: :eye
      },
      {
        label: "Modifier", 
        href: "/documents/1/edit",
        icon: :edit
      }
    ]
  end

  let(:complex_actions) do
    [
      {
        label: "Télécharger",
        href: "/documents/1/download",
        icon: :download,
        data: { turbo_method: :get }
      },
      {
        label: "Partager",
        action: "share",
        icon: :share,
        data: { action: "click->document-actions#share" }
      },
      { divider: true },
      {
        label: "Archiver",
        href: "/documents/1/archive",
        icon: :archive,
        method: :patch,
        confirm: "Êtes-vous sûr de vouloir archiver ce document ?"
      },
      { divider: true },
      {
        label: "Supprimer",
        href: "/documents/1",
        icon: :trash,
        method: :delete,
        confirm: "Êtes-vous sûr de vouloir supprimer ce document ?",
        danger: true
      }
    ]
  end

  describe "initialization" do
    it "renders with basic actions" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('[data-controller="dropdown"]')
      expect(page).to have_button(class: /inline-flex.*items-center/)
      expect(page).to have_css('[data-dropdown-target="menu"]', visible: false)
    end

    it "validates that actions is an array" do
      expect {
        described_class.new(actions: "not an array")
      }.to raise_error(ArgumentError, "actions must be an Array")
    end

    it "validates that actions have required fields" do
      invalid_actions = [{ icon: :eye }] # missing label

      expect {
        described_class.new(actions: invalid_actions)
      }.to raise_error(ArgumentError, /must have a :label/)
    end

    it "validates that actions have either href, action, or data" do
      invalid_actions = [{ label: "Test" }] # missing action/href/data

      expect {
        described_class.new(actions: invalid_actions)
      }.to raise_error(ArgumentError, /must have either :href, :action, or :data/)
    end

    it "allows divider actions without validation" do
      actions_with_divider = [
        { label: "Test", href: "/test" },
        { divider: true }
      ]

      expect {
        described_class.new(actions: actions_with_divider)
      }.not_to raise_error
    end
  end

  describe "trigger styles" do
    context "with icon_button trigger" do
      it "renders icon button trigger by default" do
        render_inline(described_class.new(actions: basic_actions))
        
        expect(page).to have_button(class: /p-1\.5.*rounded-md/)
        expect(page).to have_css('svg') # icon
        expect(page).to have_css('.sr-only', text: 'Actions')
      end

      it "renders with custom icon" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_icon: :cog
        ))
        
        expect(page).to have_css('svg')
      end

      it "supports different sizes" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_size: :lg
        ))
        
        expect(page).to have_button(class: /p-2\.5/)
      end

      it "supports different variants" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_variant: :primary
        ))
        
        expect(page).to have_button(class: /bg-indigo-600.*text-white/)
      end
    end

    context "with button trigger" do
      it "renders button with text" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_style: :button,
          trigger_text: "Actions"
        ))
        
        expect(page).to have_button("Actions", class: /px-3.*py-2.*border/)
        expect(page).to have_css('svg') # chevron down icon
      end

      it "renders button with text and custom icon" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_style: :button,
          trigger_text: "Options",
          trigger_icon: :cog
        ))
        
        expect(page).to have_button("Options")
        # Check that trigger button has 2 icons: custom icon + chevron down
        within('button[data-action="click->dropdown#toggle"]') do
          expect(page).to have_css('svg', count: 2)
        end
      end
    end

    context "with link trigger" do
      it "renders link style trigger" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_style: :link,
          trigger_text: "Options"
        ))
        
        expect(page).to have_button(class: /underline/)
      end
    end

    context "with ghost trigger" do
      it "renders ghost style trigger" do
        render_inline(described_class.new(
          actions: basic_actions,
          trigger_style: :ghost
        ))
        
        expect(page).to have_button(class: /hover:bg-gray-100/)
      end
    end
  end

  describe "menu positioning" do
    it "positions menu to the right by default" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('[data-dropdown-target="menu"].right-0')
    end

    it "positions menu to the left when specified" do
      render_inline(described_class.new(
        actions: basic_actions,
        position: "left"
      ))
      
      expect(page).to have_css('[data-dropdown-target="menu"].left-0')
    end

    it "centers menu when specified" do
      render_inline(described_class.new(
        actions: basic_actions,
        position: "center"
      ))
      
      expect(page).to have_css('[data-dropdown-target="menu"].left-1\\/2')
    end
  end

  describe "menu customization" do
    it "supports custom menu width" do
      render_inline(described_class.new(
        actions: basic_actions,
        menu_width: "w-72"
      ))
      
      expect(page).to have_css('[data-dropdown-target="menu"].w-72')
    end

    it "supports custom z-index" do
      render_inline(described_class.new(
        actions: basic_actions,
        z_index: "z-40"
      ))
      
      expect(page).to have_css('[data-dropdown-target="menu"].z-40')
    end
  end

  describe "action rendering" do
    it "renders basic actions with links" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_link("Voir", href: "/documents/1")
      expect(page).to have_link("Modifier", href: "/documents/1/edit")
    end

    it "renders actions with icons" do
      render_inline(described_class.new(actions: basic_actions))
      
      # Check for icons in the dropdown menu
      within('[data-dropdown-target="menu"]') do
        expect(page).to have_css('svg', count: 2) # One icon per action
      end
    end

    it "renders actions with custom data attributes" do
      actions = [
        {
          label: "Test Action",
          action: "test",
          data: { action: "click->test#handle", turbo_method: :post }
        }
      ]
      
      render_inline(described_class.new(actions: actions))
      
      expect(page).to have_link("Test Action", href: "test")
      expect(page).to have_css('a[data-action="click->test#handle"]')
      expect(page).to have_css('a[data-turbo-method="post"]')
    end

    it "renders actions with confirmation" do
      actions = [
        {
          label: "Delete",
          href: "/documents/1",
          method: :delete,
          confirm: "Are you sure?",
          danger: true
        }
      ]
      
      render_inline(described_class.new(actions: actions))
      
      expect(page).to have_link("Delete")
      expect(page).to have_css('a[data-turbo-confirm="Are you sure?"]')
      expect(page).to have_css('a[data-turbo-method="delete"]')
    end

    it "applies danger styling to dangerous actions" do
      actions = [
        {
          label: "Delete",
          href: "/documents/1",
          danger: true
        }
      ]
      
      render_inline(described_class.new(actions: actions))
      
      expect(page).to have_link("Delete", class: /text-red-700.*hover:bg-red-50/)
    end

    it "renders button for JavaScript-only actions" do
      actions = [
        {
          label: "JavaScript Action",
          data: { action: "click->test#handle" }
        }
      ]
      
      render_inline(described_class.new(actions: actions))
      
      expect(page).to have_button("JavaScript Action")
      expect(page).to have_css('button[data-action="click->test#handle"]')
    end
  end

  describe "action grouping with dividers" do
    it "renders complex actions with dividers" do
      render_inline(described_class.new(actions: complex_actions))
      
      # Should have multiple groups
      expect(page).to have_css('.py-1[role="none"]', count: 3)
      
      # Check that actions are in correct groups
      expect(page).to have_link("Télécharger")
      expect(page).to have_link("Partager")
      expect(page).to have_link("Archiver")
      expect(page).to have_link("Supprimer")
    end

    it "handles empty action groups gracefully" do
      actions_with_empty_groups = [
        { divider: true },
        { label: "Test", href: "/test" },
        { divider: true }
      ]
      
      render_inline(described_class.new(actions: actions_with_empty_groups))
      
      expect(page).to have_link("Test")
      expect(page).to have_css('.py-1[role="none"]', count: 1)
    end
  end

  describe "empty state" do
    it "renders empty state when no actions provided" do
      render_inline(described_class.new(actions: []))
      
      expect(page).to have_text("Aucune action disponible")
      expect(page).to have_css('.text-gray-500.italic')
    end
  end

  describe "accessibility" do
    it "includes proper ARIA attributes" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('button[aria-haspopup="true"]')
      expect(page).to have_css('button[aria-expanded="false"]')
      expect(page).to have_css('button[aria-label="Actions"]')
      
      expect(page).to have_css(
        '[data-dropdown-target="menu"][role="menu"][aria-orientation="vertical"]'
      )
    end

    it "includes proper role attributes for menu items" do
      render_inline(described_class.new(actions: basic_actions))
      
      within('[data-dropdown-target="menu"]') do
        expect(page).to have_css('[role="menuitem"]', count: 2)
        expect(page).to have_css('[tabindex="-1"]', count: 2)
      end
    end

    it "uses custom aria-label when trigger_text is provided" do
      render_inline(described_class.new(
        actions: basic_actions,
        trigger_text: "Document Options"
      ))
      
      expect(page).to have_css('button[aria-label="Document Options"]')
    end
  end

  describe "stimulus integration" do
    it "includes dropdown controller" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('[data-controller="dropdown"]')
    end

    it "includes dropdown toggle action" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('button[data-action="click->dropdown#toggle"]')
    end

    it "includes dropdown targets" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('[data-dropdown-target="button"]')
      expect(page).to have_css('[data-dropdown-target="menu"]')
    end

    it "supports additional data attributes" do
      render_inline(described_class.new(
        actions: basic_actions,
        data: { "test-value": "123", "another-attr": "value" }
      ))
      
      expect(page).to have_css('[data-controller="dropdown"][data-test-value="123"][data-another-attr="value"]')
    end
  end

  describe "responsive behavior" do
    it "includes responsive classes by default" do
      render_inline(described_class.new(actions: basic_actions))
      
      expect(page).to have_css('.relative.inline-block')
      expect(page).to have_css('[data-dropdown-target="menu"].absolute')
    end
  end
end