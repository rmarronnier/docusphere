class Ui::OptimizedImageComponent < ApplicationComponent
  def initialize(src:, alt:, lazy: true, placeholder: :blur, aspect_ratio: nil,
                 sizes: nil, srcset: nil, loading: "lazy", decoding: "async",
                 width: nil, height: nil, object_fit: :cover, **options)
    @src = src
    @alt = alt
    @lazy = lazy
    @placeholder = placeholder # :blur, :skeleton, :color, :none
    @aspect_ratio = aspect_ratio # "16/9", "4/3", "1/1", etc.
    @sizes = sizes
    @srcset = srcset
    @loading = loading
    @decoding = decoding
    @width = width
    @height = height
    @object_fit = object_fit
    @options = options
  end

  private

  attr_reader :src, :alt, :lazy, :placeholder, :aspect_ratio, :sizes, :srcset,
              :loading, :decoding, :width, :height, :object_fit, :options

  def wrapper_classes
    classes = ["optimized-image-wrapper relative overflow-hidden"]
    classes << "bg-gray-100" if placeholder != :none
    classes << aspect_ratio_class if aspect_ratio
    classes << options[:wrapper_class] if options[:wrapper_class]
    classes.join(" ")
  end

  def image_classes
    classes = ["optimized-image"]
    classes << object_fit_class
    classes << "w-full h-full" unless width || height
    classes << options[:class] if options[:class]
    classes.join(" ")
  end

  def aspect_ratio_class
    case aspect_ratio
    when "16/9", "video"
      "aspect-video"
    when "4/3"
      "aspect-4-3"
    when "1/1", "square"
      "aspect-square"
    when String
      # Custom aspect ratio
      "aspect-[#{aspect_ratio}]"
    else
      nil
    end
  end

  def object_fit_class
    case object_fit
    when :contain
      "object-contain"
    when :cover
      "object-cover"
    when :fill
      "object-fill"
    when :none
      "object-none"
    when :"scale-down"
      "object-scale-down"
    else
      "object-cover"
    end
  end

  def placeholder_content
    case placeholder
    when :blur
      blur_placeholder
    when :skeleton
      skeleton_placeholder
    when :color
      color_placeholder
    else
      nil
    end
  end

  def blur_placeholder
    # Generate a small blurred version or use a data URL
    content_tag(:div, nil, 
      class: "absolute inset-0 bg-gray-200",
      style: "filter: blur(20px);"
    )
  end

  def skeleton_placeholder
    content_tag(:div, nil, 
      class: "absolute inset-0 skeleton"
    )
  end

  def color_placeholder
    # Use dominant color from image metadata if available
    content_tag(:div, nil, 
      class: "absolute inset-0 bg-gray-200"
    )
  end

  def image_attributes
    attrs = {
      class: image_classes,
      alt: alt,
      loading: loading,
      decoding: decoding
    }

    if lazy
      attrs[:"data-controller"] = "lazy-load"
      attrs[:"data-src"] = src
      attrs[:"data-lazy-load-src-value"] = src
    else
      attrs[:src] = src
    end

    attrs[:width] = width if width
    attrs[:height] = height if height
    attrs[:sizes] = sizes if sizes
    attrs[:srcset] = srcset if srcset

    attrs.merge(options.except(:class, :wrapper_class))
  end

  def noscript_fallback
    return unless lazy
    
    content_tag(:noscript) do
      image_tag(src, alt: alt, class: image_classes, loading: "lazy")
    end
  end
end