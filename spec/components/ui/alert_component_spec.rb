require 'rails_helper'

RSpec.describe Ui::AlertComponent, type: :component do
  describe "basic rendering" do
    it "renders alert with message" do
      render_inline(described_class.new(message: "This is an alert message"))
      
      expect(page).to have_text("This is an alert message")
      expect(page).to have_css(".p-3")
    end

    it "renders alert with title and message" do
      render_inline(described_class.new(
        title: "Important Notice",
        message: "Please read this carefully"
      ))
      
      expect(page).to have_text("Important Notice")
      expect(page).to have_text("Please read this carefully")
    end

    it "renders with default info type" do
      render_inline(described_class.new(message: "Info message"))
      
      expect(page).to have_css(".bg-blue-50")
      expect(page).to have_css(".border-blue-400")
      expect(page).to have_css(".text-blue-700")
    end
  end

  describe "alert types" do
    it "renders info alert" do
      render_inline(described_class.new(type: :info, message: "Info"))
      
      expect(page).to have_css(".bg-blue-50")
      expect(page).to have_css(".border-blue-400")
      expect(page).to have_css(".text-blue-700")
      expect(page).to have_css(".text-blue-400") # Icon color
    end

    it "renders success alert" do
      render_inline(described_class.new(type: :success, message: "Success"))
      
      expect(page).to have_css(".bg-green-50")
      expect(page).to have_css(".border-green-400")
      expect(page).to have_css(".text-green-700")
      expect(page).to have_css(".text-green-400") # Icon color
    end

    it "renders warning alert" do
      render_inline(described_class.new(type: :warning, message: "Warning"))
      
      expect(page).to have_css(".bg-yellow-50")
      expect(page).to have_css(".border-yellow-400")
      expect(page).to have_css(".text-yellow-700")
      expect(page).to have_css(".text-yellow-400") # Icon color
    end

    it "renders error alert" do
      render_inline(described_class.new(type: :error, message: "Error"))
      
      expect(page).to have_css(".bg-red-50")
      expect(page).to have_css(".border-red-400")
      expect(page).to have_css(".text-red-700")
      expect(page).to have_css(".text-red-400") # Icon color
    end

    it "handles invalid type gracefully" do
      render_inline(described_class.new(type: :invalid, message: "Test"))
      
      # Should fall back to info type
      expect(page).to have_css(".bg-blue-50")
      expect(page).to have_css(".border-blue-400")
    end
  end

  describe "icons" do
    it "shows appropriate icon for each type" do
      # Info icon
      render_inline(described_class.new(type: :info, message: "Info"))
      expect(page).to have_css("svg") # Information circle icon

      # Success icon
      render_inline(described_class.new(type: :success, message: "Success"))
      expect(page).to have_css("svg") # Check circle icon

      # Warning icon
      render_inline(described_class.new(type: :warning, message: "Warning"))
      expect(page).to have_css("svg") # Exclamation icon

      # Error icon
      render_inline(described_class.new(type: :error, message: "Error"))
      expect(page).to have_css("svg") # X circle icon
    end

    it "shows icon by default" do
      render_inline(described_class.new(message: "Message"))
      
      expect(page).to have_css("svg")
    end
  end

  describe "border positions" do
    it "shows left border by default" do
      render_inline(described_class.new(message: "Test"))
      
      expect(page).to have_css(".border-l-4")
    end

    it "shows top border" do
      render_inline(described_class.new(
        message: "Test",
        border_position: :top
      ))
      
      expect(page).to have_css(".border-t-4")
      expect(page).not_to have_css(".border-l-4")
    end

    it "shows all borders" do
      render_inline(described_class.new(
        message: "Test",
        border_position: :all
      ))
      
      expect(page).to have_css(".border")
      expect(page).not_to have_css(".border-l-4")
      expect(page).not_to have_css(".border-t-4")
    end

    it "handles invalid border position" do
      render_inline(described_class.new(
        message: "Test",
        border_position: :invalid
      ))
      
      # Should fall back to left border
      expect(page).to have_css(".border-l-4")
    end
  end

  describe "dismissible alerts" do
    it "is not dismissible by default" do
      render_inline(described_class.new(message: "Test"))
      
      expect(page).not_to have_css("[data-controller='alert']")
      expect(page).not_to have_css("button")
    end

    it "shows dismiss button when dismissible" do
      render_inline(described_class.new(
        message: "Dismissible alert",
        dismissible: true
      ))
      
      expect(page).to have_css("[data-controller='alert']")
      expect(page).to have_css("[data-action='click->alert#dismiss']")
      expect(page).to have_css("button")
    end

    it "includes close icon in dismiss button" do
      render_inline(described_class.new(
        message: "Test",
        dismissible: true
      ))
      
      within("button") do
        expect(page).to have_css("svg")
      end
    end
  end

  describe "content layout" do
    it "layouts icon and content properly" do
      render_inline(described_class.new(
        title: "Title",
        message: "Message"
      ))
      
      expect(page).to have_css(".flex") # Flex container
      expect(page).to have_css("svg") # Icon
      expect(page).to have_text("Title")
      expect(page).to have_text("Message")
    end

    it "handles long content" do
      long_message = "This is a very long message " * 10
      
      render_inline(described_class.new(message: long_message))
      
      expect(page).to have_text(long_message.strip)
    end
  end

  describe "accessibility" do
    it "has proper ARIA role" do
      render_inline(described_class.new(
        type: :error,
        message: "Error message"
      ))
      
      expect(page).to have_css("[role='alert']")
    end

    it "has proper ARIA live region for important alerts" do
      render_inline(described_class.new(
        type: :error,
        message: "Critical error"
      ))
      
      expect(page).to have_css("[aria-live='assertive']")
    end

    it "has proper ARIA live region for non-critical alerts" do
      render_inline(described_class.new(
        type: :info,
        message: "Information"
      ))
      
      expect(page).to have_css("[aria-live='polite']")
    end

    it "dismiss button has ARIA label" do
      render_inline(described_class.new(
        message: "Test",
        dismissible: true
      ))
      
      expect(page).to have_css("button[aria-label='Dismiss alert']")
    end
  end

  describe "stimulus integration" do
    it "includes alert controller for dismissible alerts" do
      render_inline(described_class.new(
        message: "Test",
        dismissible: true
      ))
      
      expect(page).to have_css("[data-controller='alert']")
      expect(page).to have_css("[data-action='click->alert#dismiss']")
    end

    it "does not include controller for non-dismissible alerts" do
      render_inline(described_class.new(
        message: "Test",
        dismissible: false
      ))
      
      expect(page).not_to have_css("[data-controller='alert']")
    end
  end

  describe "custom styling" do
    it "maintains consistent padding" do
      render_inline(described_class.new(message: "Test"))
      
      expect(page).to have_css(".p-3")
    end

    it "has rounded corners and overflow hidden" do
      render_inline(described_class.new(message: "Test"))
      
      expect(page).to have_css("[class*='rounded']")
      expect(page).to have_css("[class*='overflow-hidden']")
    end
  end

  describe "edge cases" do
    it "handles nil message" do
      render_inline(described_class.new(message: nil))
      
      expect(page).to have_css(".p-3") # Alert renders but empty
    end

    it "handles empty message" do
      render_inline(described_class.new(message: ""))
      
      expect(page).to have_css(".p-3") # Alert renders but empty
    end

    it "renders with only title" do
      render_inline(described_class.new(title: "Title only"))
      
      expect(page).to have_text("Title only")
    end
  end
end