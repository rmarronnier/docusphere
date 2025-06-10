require 'rails_helper'

RSpec.describe Ui::ModalComponent, type: :component do
  describe "basic rendering" do
    it "renders modal with required id" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Modal content" }
      end
      
      expect(page).to have_css("#test-modal")
      expect(page).to have_text("Modal content")
    end

    it "renders with title" do
      render_inline(described_class.new(id: "test-modal", title: "Modal Title")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_text("Modal Title")
    end

    it "has hidden class by default" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".hidden")
    end
  end

  describe "modal sections" do
    it "renders header slot" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_header { "Custom Header" }
        modal.with_body { "Body" }
      end
      
      expect(page).to have_text("Custom Header")
    end

    it "renders body slot" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Body Content" }
      end
      
      expect(page).to have_text("Body Content")
    end

    it "renders footer slot" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Body" }
        modal.with_footer { "Footer Content" }
      end
      
      expect(page).to have_text("Footer Content")
    end

    it "renders all three sections" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_header { "Header" }
        modal.with_body { "Body" }
        modal.with_footer { "Footer" }
      end
      
      expect(page).to have_text("Header")
      expect(page).to have_text("Body")
      expect(page).to have_text("Footer")
    end
  end

  describe "modal sizes" do
    it "renders with default medium size" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".max-w-2xl")
    end

    it "renders small modal" do
      render_inline(described_class.new(id: "test-modal", size: :sm)) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".max-w-md")
    end

    it "renders large modal" do
      render_inline(described_class.new(id: "test-modal", size: :lg)) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".max-w-4xl")
    end

    it "renders extra large modal" do
      render_inline(described_class.new(id: "test-modal", size: :xl)) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".max-w-6xl")
    end

    it "renders full width modal" do
      render_inline(described_class.new(id: "test-modal", size: :full)) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".max-w-full")
      expect(page).to have_css(".mx-4")
    end
  end

  describe "close button" do
    it "shows close button by default" do
      render_inline(described_class.new(id: "test-modal", title: "Test")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("button[data-modal-hide='test-modal']")
    end

    it "can hide close button" do
      render_inline(described_class.new(id: "test-modal", closable: false)) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).not_to have_css("button[data-modal-hide]")
    end

    it "close button has proper aria label" do
      render_inline(described_class.new(id: "test-modal", title: "Test")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("button[aria-label='Close modal']")
    end
  end

  describe "backdrop behavior" do
    it "allows backdrop dismiss by default" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[data-modal-hide='test-modal']")
    end

    it "can disable backdrop dismiss" do
      render_inline(described_class.new(
        id: "test-modal",
        backdrop_dismiss: false
      )) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[data-modal-backdrop='static']")
      # The backdrop should not have data-modal-hide
    end
  end

  describe "modal structure" do
    it "has proper modal container structure" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".relative.w-full.max-h-full")
      expect(page).to have_css(".bg-white.rounded-lg.shadow")
    end

    it "has backdrop overlay" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".bg-gray-900.bg-opacity-50")
    end

    it "positions modal in center" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".justify-center.items-center")
    end
  end

  describe "accessibility" do
    it "has proper ARIA attributes" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[tabindex='-1']")
      expect(page).to have_css("[aria-hidden='true']")
    end

    it "has proper role attribute" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[role='dialog']")
    end

    it "has aria-modal attribute" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[aria-modal='true']")
    end

    it "has aria-labelledby when title is present" do
      render_inline(described_class.new(
        id: "test-modal",
        title: "Modal Title"
      )) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[aria-labelledby='test-modal-title']")
      expect(page).to have_css("#test-modal-title", text: "Modal Title")
    end
  end

  describe "scrolling behavior" do
    it "allows scrolling for long content" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".overflow-y-auto.overflow-x-hidden")
    end

    it "limits modal height" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".max-h-full")
      expect(page).to have_css(".h-\\[calc\\(100\\%-1rem\\)\\]")
    end
  end

  describe "z-index layering" do
    it "has high z-index for overlay" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".z-50")
    end
  end

  describe "stimulus integration" do
    it "includes modal controller data attributes" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[data-modal-backdrop]")
    end

    it "includes hide trigger on close button" do
      render_inline(described_class.new(id: "test-modal", title: "Test")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css("[data-modal-hide='test-modal']")
    end
  end

  describe "responsive design" do
    it "has responsive padding" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".p-4.md\\:p-5")
    end

    it "adapts width on mobile" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      expect(page).to have_css(".w-full.md\\:inset-0")
    end
  end

  describe "animation classes" do
    it "is prepared for animations" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Content" }
      end
      
      # Modal should have classes ready for fade/slide animations
      expect(page).to have_css(".hidden") # Hidden by default, JS will handle show/hide
    end
  end

  describe "custom content" do
    it "allows complex content in body" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body do
          '<form><input type="text" placeholder="Enter name"></form>'.html_safe
        end
      end
      
      expect(page).to have_css("form")
      expect(page).to have_css("input[type='text']")
    end

    it "allows action buttons in footer" do
      render_inline(described_class.new(id: "test-modal")) do |modal|
        modal.with_body { "Confirm this action?" }
        modal.with_footer do
          '<div class="flex gap-2"><button class="btn btn-secondary">Cancel</button><button class="btn btn-primary">Confirm</button></div>'.html_safe
        end
      end
      
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Confirm")
    end
  end
end