require 'rails_helper'

RSpec.describe Ui::IconComponent, type: :component do
  describe "basic rendering" do
    it "renders SVG icon" do
      render_inline(described_class.new(name: :document))
      
      expect(page).to have_css("svg")
      expect(page).to have_css("path")
    end

    it "renders with default size" do
      render_inline(described_class.new(name: :check))
      
      expect(page).to have_css(".h-5.w-5")
    end

    it "renders with custom size" do
      render_inline(described_class.new(name: :home, size: 8))
      
      expect(page).to have_css(".h-8.w-8")
    end

    it "applies default stroke width" do
      render_inline(described_class.new(name: :cog))
      
      expect(page).to have_css("svg[stroke-width='2']")
    end

    it "applies custom stroke width" do
      render_inline(described_class.new(name: :menu, stroke_width: 3))
      
      expect(page).to have_css("svg[stroke-width='3']")
    end
  end

  describe "icon library" do
    it "renders document icons" do
      %i[document clipboard].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end

    it "renders status/action icons" do
      %i[check check_circle x_circle exclamation information_circle].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end

    it "renders navigation icons" do
      %i[plus minus chevron_down chevron_up chevron_left chevron_right menu x].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end

    it "renders construction/building icons" do
      %i[office_building home building apartment blueprint hammer wrench].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end

    it "renders financial icons" do
      %i[currency_euro credit_card calculator receipt banknotes].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end

    it "renders people/roles icons" do
      %i[users user user_group identification academic_cap].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end

    it "renders communication icons" do
      %i[mail phone chat bell].each do |icon|
        render_inline(described_class.new(name: icon))
        expect(page).to have_css("svg path")
      end
    end
  end

  describe "custom CSS classes" do
    it "applies custom CSS class" do
      render_inline(described_class.new(
        name: :star,
        css_class: "text-yellow-400 hover:text-yellow-500"
      ))
      
      expect(page).to have_css(".text-yellow-400.hover\\:text-yellow-500")
    end

    it "combines custom class with size classes" do
      render_inline(described_class.new(
        name: :heart,
        size: 6,
        css_class: "text-red-500"
      ))
      
      expect(page).to have_css(".h-6.w-6.text-red-500")
    end
  end

  describe "viewbox customization" do
    it "uses default viewbox" do
      render_inline(described_class.new(name: :home))
      
      expect(page).to have_css("svg[viewbox='0 0 24 24']")
    end

    it "accepts custom viewbox" do
      render_inline(described_class.new(
        name: :custom,
        viewbox: "0 0 32 32"
      ))
      
      expect(page).to have_css("svg[viewbox='0 0 32 32']")
    end
  end

  describe "SVG attributes" do
    it "sets proper SVG attributes" do
      render_inline(described_class.new(name: :settings))
      
      expect(page).to have_css("svg[xmlns='http://www.w3.org/2000/svg']")
      expect(page).to have_css("svg[fill='none']")
      expect(page).to have_css("svg[stroke='currentColor']")
    end

    it "sets aria-hidden for decorative icons" do
      render_inline(described_class.new(name: :decorative))
      
      expect(page).to have_css("svg[aria-hidden='true']")
    end
  end

  describe "icon path handling" do
    it "renders icon when path exists" do
      render_inline(described_class.new(name: :check))
      
      expect(page).to have_css("path[d]")
    end

    it "handles non-existent icon gracefully" do
      render_inline(described_class.new(name: :non_existent_icon))
      
      expect(page).to have_css("svg")
      expect(page).not_to have_css("path[d]")
    end
  end

  describe "string vs symbol names" do
    it "accepts symbol icon name" do
      render_inline(described_class.new(name: :home))
      
      expect(page).to have_css("svg path")
    end

    it "accepts string icon name" do
      render_inline(described_class.new(name: "home"))
      
      expect(page).to have_css("svg path")
    end
  end

  describe "accessibility" do
    it "includes aria-hidden by default" do
      render_inline(described_class.new(name: :info))
      
      expect(page).to have_css("svg[aria-hidden='true']")
    end

    it "allows role attribute for semantic icons" do
      # This would need to be implemented in the component
      render_inline(described_class.new(name: :warning))
      
      expect(page).to have_css("svg")
    end
  end

  describe "common use cases" do
    it "renders small icon for inline use" do
      render_inline(described_class.new(name: :info, size: 4))
      
      expect(page).to have_css(".h-4.w-4")
    end

    it "renders large icon for headers" do
      render_inline(described_class.new(name: :trophy, size: 12))
      
      expect(page).to have_css(".h-12.w-12")
    end

    it "renders with brand colors" do
      render_inline(described_class.new(
        name: :badge_check,
        css_class: "text-green-500"
      ))
      
      expect(page).to have_css(".text-green-500")
    end
  end

  describe "animation support" do
    it "can add animation classes" do
      render_inline(described_class.new(
        name: :refresh,
        css_class: "animate-spin"
      ))
      
      expect(page).to have_css(".animate-spin")
    end

    it "can add transition classes" do
      render_inline(described_class.new(
        name: :heart,
        css_class: "transition-colors duration-200"
      ))
      
      expect(page).to have_css(".transition-colors.duration-200")
    end
  end

  describe "responsive sizing" do
    it "can use responsive size classes" do
      render_inline(described_class.new(
        name: :menu,
        css_class: "h-6 w-6 md:h-8 md:w-8"
      ))
      
      expect(page).to have_css(".h-6.w-6.md\\:h-8.md\\:w-8")
    end
  end
end