require 'rails_helper'

RSpec.describe Immo::Promo::Shared::HeaderCardComponent, type: :component do
  let(:basic_title) { "Test Title" }
  let(:basic_subtitle) { "Test subtitle" }

  describe "basic rendering" do
    it "renders with only title" do
      rendered = render_inline(described_class.new(title: basic_title))
      
      expect(rendered).to have_css('h1', text: basic_title)
      expect(rendered).to have_css('div[role="banner"]')
      expect(rendered).to have_css('h1#page-title')
    end

    it "renders with title and subtitle" do
      rendered = render_inline(described_class.new(
        title: basic_title,
        subtitle: basic_subtitle
      ))
      
      expect(rendered).to have_css('h1', text: basic_title)
      expect(rendered).to have_css('p', text: basic_subtitle)
      expect(rendered).to have_css('p[aria-describedby="page-title"]')
    end

    it "does not render subtitle section when subtitle is nil" do
      rendered = render_inline(described_class.new(title: basic_title, subtitle: nil))
      
      expect(rendered).not_to have_css('p')
    end

    it "does not render subtitle section when subtitle is blank" do
      rendered = render_inline(described_class.new(title: basic_title, subtitle: ""))
      
      expect(rendered).not_to have_css('p')
    end
  end

  describe "size variants" do
    it "renders small size correctly" do
      rendered = render_inline(described_class.new(title: basic_title, size: :small))
      
      expect(rendered).to have_css('h1.text-lg.font-semibold')
    end

    it "renders medium size correctly" do
      rendered = render_inline(described_class.new(title: basic_title, size: :medium))
      
      expect(rendered).to have_css('h1.text-xl.font-semibold')
    end

    it "renders large size correctly (default)" do
      rendered = render_inline(described_class.new(title: basic_title, size: :large))
      
      expect(rendered).to have_css('h1.text-2xl.font-bold')
    end

    it "renders extra_large size correctly" do
      rendered = render_inline(described_class.new(title: basic_title, size: :extra_large))
      
      expect(rendered).to have_css('h1.text-3xl.font-bold')
    end

    it "defaults to large size when invalid size provided" do
      rendered = render_inline(described_class.new(title: basic_title, size: :invalid))
      
      expect(rendered).to have_css('h1.text-2xl.font-bold')
    end
  end

  describe "background and styling options" do
    it "renders with background by default" do
      rendered = render_inline(described_class.new(title: basic_title))
      
      expect(rendered).to have_css('div.bg-white.shadow.rounded-lg.p-6')
    end

    it "renders without background when show_background is false" do
      rendered = render_inline(described_class.new(title: basic_title, show_background: false))
      
      expect(rendered).not_to have_css('.bg-white')
      expect(rendered).not_to have_css('.shadow')
      expect(rendered).not_to have_css('.rounded-lg')
      expect(rendered).not_to have_css('.p-6')
    end

    it "applies custom background color" do
      rendered = render_inline(described_class.new(
        title: basic_title,
        background_color: 'bg-blue-50'
      ))
      
      expect(rendered).to have_css('div.bg-blue-50')
    end

    it "renders without shadow when shadow is false" do
      rendered = render_inline(described_class.new(title: basic_title, shadow: false))
      
      expect(rendered).to have_css('div.bg-white')
      expect(rendered).not_to have_css('.shadow')
    end

    it "applies custom padding" do
      rendered = render_inline(described_class.new(
        title: basic_title,
        padding: 'p-4'
      ))
      
      expect(rendered).to have_css('div.p-4')
    end

    it "applies custom border radius" do
      rendered = render_inline(described_class.new(
        title: basic_title,
        border_radius: 'rounded-xl'
      ))
      
      expect(rendered).to have_css('div.rounded-xl')
    end

    it "applies extra classes" do
      rendered = render_inline(described_class.new(
        title: basic_title,
        extra_classes: 'custom-class another-class'
      ))
      
      expect(rendered).to have_css('div.custom-class.another-class')
    end
  end

  describe "actions" do
    it "does not render actions section when no actions provided" do
      rendered = render_inline(described_class.new(title: basic_title))
      
      expect(rendered).not_to have_css('div[role="group"]')
    end

    it "does not render actions section when empty array provided" do
      rendered = render_inline(described_class.new(title: basic_title, actions: []))
      
      expect(rendered).not_to have_css('div[role="group"]')
    end

    it "renders actions section when actions provided" do
      actions = [{ text: "Test Action", href: "/test" }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('div[role="group"][aria-label="Actions de la page"]')
    end

    it "handles string actions" do
      actions = ["<button>Test</button>"]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('button', text: 'Test')
    end

    it "handles single action (not array)" do
      action = { text: "Single Action", href: "/single" }
      rendered = render_inline(described_class.new(title: basic_title, actions: action))
      
      expect(rendered).to have_css('a', text: 'Single Action')
      expect(rendered).to have_css('a[href="/single"]')
    end
  end

  describe "action rendering" do
    it "renders primary action correctly" do
      actions = [{
        text: "Primary Action",
        href: "/primary",
        type: :primary
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('a.bg-indigo-600.text-white', text: 'Primary Action')
      expect(rendered).to have_css('a[href="/primary"]')
    end

    it "renders secondary action correctly" do
      actions = [{
        text: "Secondary Action",
        href: "/secondary",
        type: :secondary
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('a.bg-white.text-gray-900.ring-1', text: 'Secondary Action')
      expect(rendered).to have_css('a[href="/secondary"]')
    end

    it "renders button action with method" do
      actions = [{
        text: "Delete",
        url: "/delete",
        method: :delete,
        type: :secondary
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('form[action="/delete"]')
      expect(rendered).to have_css('input[name="_method"][value="delete"]', visible: false)
      expect(rendered).to have_css('button[type="submit"]', text: 'Delete')
    end

    it "renders button action with data attributes" do
      actions = [{
        text: "Modal Action",
        url: "/modal",
        data: { modal: 'open', target: 'test-modal' }
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('form[data-modal="open"][data-target="test-modal"]')
    end

    it "renders raw HTML action" do
      actions = [{
        html: '<button class="custom-button">Custom HTML</button>'
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('button.custom-button', text: 'Custom HTML')
    end

    it "applies extra classes to action" do
      actions = [{
        text: "Test Action",
        href: "/test",
        extra_classes: "ml-2 custom-action"
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('a.ml-2.custom-action')
    end

    it "uses custom classes over default type classes" do
      actions = [{
        text: "Custom Action",
        href: "/custom",
        class: "bg-red-500 text-white custom-style"
      }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('a.bg-red-500.text-white.custom-style')
    end

    it "handles multiple actions" do
      actions = [
        { text: "Action 1", href: "/action1", type: :primary },
        { text: "Action 2", href: "/action2", type: :secondary },
        { text: "Action 3", href: "/action3" }
      ]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('a', text: 'Action 1')
      expect(rendered).to have_css('a', text: 'Action 2')
      expect(rendered).to have_css('a', text: 'Action 3')
      expect(rendered).to have_css('a.bg-indigo-600', text: 'Action 1')
      expect(rendered).to have_css('a.bg-white.ring-1', text: 'Action 2')
    end
  end

  describe "responsive layout" do
    it "includes responsive layout classes" do
      rendered = render_inline(described_class.new(title: basic_title))
      
      expect(rendered).to have_css('div.md\\:flex.md\\:items-center.md\\:justify-between')
      expect(rendered).to have_css('div.min-w-0.flex-1')
    end

    it "includes responsive action classes when actions present" do
      actions = [{ text: "Test", href: "/test" }]
      rendered = render_inline(described_class.new(title: basic_title, actions: actions))
      
      expect(rendered).to have_css('div.mt-4.flex.flex-wrap.gap-3.md\\:ml-4.md\\:mt-0')
    end
  end

  describe "accessibility" do
    it "includes proper ARIA attributes" do
      rendered = render_inline(described_class.new(
        title: basic_title,
        subtitle: basic_subtitle,
        actions: [{ text: "Test", href: "/test" }]
      ))
      
      expect(rendered).to have_css('div[role="banner"]')
      expect(rendered).to have_css('div[aria-label="' + basic_title + '"]')
      expect(rendered).to have_css('h1#page-title')
      expect(rendered).to have_css('p[aria-describedby="page-title"]')
      expect(rendered).to have_css('div[role="group"][aria-label="Actions de la page"]')
    end
  end
end