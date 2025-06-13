require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#breadcrumb_component" do
    let(:basic_items) do
      [
        { name: "GED", path: "/ged" },
        { name: "Documents", path: "/ged/documents" }
      ]
    end

    it "renders breadcrumb component with provided items" do
      result = helper.breadcrumb_component(basic_items)
      expect(result).to be_present
      expect(result).to include("nav")
      expect(result).to include("aria-label=\"Breadcrumb\"")
    end

    it "uses GED defaults (no home, GED separator, no mobile back)" do
      # Since we can't easily test the component internals from helper,
      # we check that the component is created with correct defaults
      expect(Navigation::BreadcrumbComponent).to receive(:new).with(
        items: basic_items,
        separator: :ged,
        show_home: false,
        mobile_back: false
      ).and_call_original

      helper.breadcrumb_component(basic_items)
    end

    it "allows overriding defaults" do
      expect(Navigation::BreadcrumbComponent).to receive(:new).with(
        items: basic_items,
        separator: :chevron,
        show_home: true,
        mobile_back: true
      ).and_call_original

      helper.breadcrumb_component(basic_items, 
        separator: :chevron, 
        show_home: true, 
        mobile_back: true
      )
    end

    it "passes through custom options" do
      expect(Navigation::BreadcrumbComponent).to receive(:new).with(
        items: basic_items,
        separator: :ged,
        show_home: false,
        mobile_back: false,
        class: "custom-breadcrumb"
      ).and_call_original

      helper.breadcrumb_component(basic_items, class: "custom-breadcrumb")
    end
  end

  describe "#ged_breadcrumb" do
    let(:items) do
      [
        { name: "GED", path: "/ged" },
        { name: "Space", path: "/ged/spaces/1" }
      ]
    end

    it "is an alias for breadcrumb_component" do
      expect(helper).to receive(:breadcrumb_component).with(items)
      helper.ged_breadcrumb(items)
    end

    it "passes options through to breadcrumb_component" do
      options = { truncate: false }
      expect(helper).to receive(:breadcrumb_component).with(items, options)
      helper.ged_breadcrumb(items, options)
    end
  end
end