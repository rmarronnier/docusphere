require 'rails_helper'

RSpec.describe Ui::NotificationComponent, type: :component do
  it "renders info notification by default" do
    rendered = render_inline(described_class.new) do
      "This is an info message"
    end
    
    expect(rendered).to have_css('.bg-blue-50')
    expect(rendered).to have_text('This is an info message')
  end

  it "renders different notification types" do
    success = render_inline(described_class.new(type: :success)) { "Success!" }
    warning = render_inline(described_class.new(type: :warning)) { "Warning!" }
    error = render_inline(described_class.new(type: :error)) { "Error!" }
    
    expect(success).to have_css('.bg-green-50')
    expect(warning).to have_css('.bg-yellow-50')
    expect(error).to have_css('.bg-red-50')
  end

  it "renders with title" do
    rendered = render_inline(described_class.new(title: 'Important Notice')) do
      "Please read this carefully"
    end
    
    expect(rendered).to have_text('Important Notice')
    expect(rendered).to have_text('Please read this carefully')
  end

  it "renders dismissible notification" do
    rendered = render_inline(described_class.new(dismissible: true)) do
      "Dismissible message"
    end
    
    expect(rendered).to have_css('button[data-action="click->notification#dismiss"]')
    expect(rendered).to have_text('Fermer')
  end

  it "renders non-dismissible notification" do
    rendered = render_inline(described_class.new(dismissible: false)) do
      "Non-dismissible message"
    end
    
    expect(rendered).not_to have_css('button')
  end

  it "renders appropriate icons for each type" do
    success = render_inline(described_class.new(type: :success)) { "Success" }
    warning = render_inline(described_class.new(type: :warning)) { "Warning" }
    error = render_inline(described_class.new(type: :error)) { "Error" }
    info = render_inline(described_class.new(type: :info)) { "Info" }
    
    # Each should have an SVG icon
    expect(success).to have_css('svg')
    expect(warning).to have_css('svg')
    expect(error).to have_css('svg')
    expect(info).to have_css('svg')
  end
end