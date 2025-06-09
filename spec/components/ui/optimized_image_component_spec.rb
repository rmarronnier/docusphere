require 'rails_helper'

RSpec.describe Ui::OptimizedImageComponent, type: :component do
  let(:test_image_src) { "/assets/test-image.jpg" }
  let(:test_alt_text) { "Test image description" }

  describe "basic rendering" do
    it "renders image with required attributes" do
      render_inline(described_class.new(src: test_image_src, alt: test_alt_text))
      
      expect(page).to have_css(".optimized-image-wrapper")
      expect(page).to have_css(".optimized-image")
      expect(page).to have_css("[alt='#{test_alt_text}']")
    end

    it "uses lazy loading by default" do
      render_inline(described_class.new(src: test_image_src, alt: test_alt_text))
      
      expect(page).to have_css("[data-controller='lazy-load']")
      expect(page).to have_css("[data-lazy-load-src-value='#{test_image_src}']")
      expect(page).not_to have_css("img[src='#{test_image_src}']")
    end

    it "can disable lazy loading" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        lazy: false
      ))
      
      expect(page).to have_css("img[src='#{test_image_src}']")
      expect(page).not_to have_css("[data-controller='lazy-load']")
    end
  end

  describe "aspect ratios" do
    it "applies video aspect ratio (16:9)" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        aspect_ratio: "16/9"
      ))
      
      expect(page).to have_css(".aspect-video")
    end

    it "applies square aspect ratio (1:1)" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        aspect_ratio: "1/1"
      ))
      
      expect(page).to have_css(".aspect-square")
    end

    it "applies custom aspect ratio" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        aspect_ratio: "21/9"
      ))
      
      expect(page).to have_css(".aspect-\\[21\\/9\\]")
    end

    it "works without aspect ratio" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        aspect_ratio: nil
      ))
      
      expect(page).not_to have_css("[class*='aspect-']")
    end
  end

  describe "placeholder options" do
    it "shows blur placeholder by default" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        placeholder: :blur
      ))
      
      expect(page).to have_css(".bg-gray-100")
      expect(page).to have_css("div[style*='blur']")
    end

    it "shows skeleton placeholder" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        placeholder: :skeleton
      ))
      
      expect(page).to have_css(".skeleton")
    end

    it "shows color placeholder" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        placeholder: :color
      ))
      
      expect(page).to have_css(".bg-gray-200")
    end

    it "shows no placeholder when specified" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        placeholder: :none
      ))
      
      expect(page).not_to have_css(".bg-gray-100")
    end
  end

  describe "object fit options" do
    %i[contain cover fill none scale-down].each do |fit|
      it "applies object-#{fit} class" do
        render_inline(described_class.new(
          src: test_image_src,
          alt: test_alt_text,
          object_fit: fit
        ))
        
        expect(page).to have_css(".object-#{fit.to_s.gsub('_', '-')}")
      end
    end

    it "defaults to object-cover" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text
      ))
      
      expect(page).to have_css(".object-cover")
    end
  end

  describe "responsive images" do
    it "accepts sizes attribute" do
      sizes_value = "(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
      
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        sizes: sizes_value,
        lazy: false
      ))
      
      expect(page).to have_css("img[sizes='#{sizes_value}']")
    end

    it "accepts srcset attribute" do
      srcset_value = "/image-320w.jpg 320w, /image-640w.jpg 640w, /image-1280w.jpg 1280w"
      
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        srcset: srcset_value,
        lazy: false
      ))
      
      expect(page).to have_css("img[srcset='#{srcset_value}']")
    end
  end

  describe "dimensions" do
    it "accepts width and height" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        width: 600,
        height: 400,
        lazy: false
      ))
      
      expect(page).to have_css("img[width='600'][height='400']")
    end

    it "applies full size classes when no dimensions specified" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text
      ))
      
      expect(page).to have_css(".w-full.h-full")
    end
  end

  describe "loading and decoding attributes" do
    it "sets loading='lazy' by default" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        lazy: false
      ))
      
      expect(page).to have_css("img[loading='lazy']")
    end

    it "sets decoding='async' by default" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        lazy: false
      ))
      
      expect(page).to have_css("img[decoding='async']")
    end

    it "allows custom loading attribute" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        loading: "eager",
        lazy: false
      ))
      
      expect(page).to have_css("img[loading='eager']")
    end
  end

  describe "noscript fallback" do
    it "includes noscript fallback for lazy loaded images" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        lazy: true
      ))
      
      expect(page.native.to_s).to include("<noscript>")
      expect(page.native.to_s).to include("src=\"#{test_image_src}\"")
    end

    it "does not include noscript for non-lazy images" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        lazy: false
      ))
      
      expect(page.native.to_s).not_to include("<noscript>")
    end
  end

  describe "custom classes and attributes" do
    it "accepts custom wrapper classes" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        wrapper_class: "custom-wrapper-class"
      ))
      
      expect(page).to have_css(".optimized-image-wrapper.custom-wrapper-class")
    end

    it "accepts custom image classes" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        class: "custom-image-class"
      ))
      
      expect(page).to have_css(".optimized-image.custom-image-class")
    end

    it "passes through additional attributes" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        data: { testid: "hero-image" },
        lazy: false
      ))
      
      expect(page).to have_css("img[data-testid='hero-image']")
    end
  end

  describe "accessibility" do
    it "requires alt text" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: "Descriptive alt text"
      ))
      
      expect(page).to have_css("[alt='Descriptive alt text']")
    end

    it "handles empty alt text for decorative images" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: ""
      ))
      
      expect(page).to have_css("[alt='']")
    end
  end

  describe "stimulus integration" do
    it "includes lazy load controller when lazy loading enabled" do
      render_inline(described_class.new(
        src: test_image_src,
        alt: test_alt_text,
        lazy: true
      ))
      
      expect(page).to have_css("[data-controller='lazy-load']")
      expect(page).to have_css("[data-src='#{test_image_src}']")
    end
  end
end