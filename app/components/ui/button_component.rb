class Ui::ButtonComponent < ApplicationComponent
  def initialize(variant: :primary, size: :md, **options)
    @variant = variant
    @size = size
    @options = options
  end

  private

  attr_reader :variant, :size, :options

  def classes
    base_classes = "btn"
    variant_classes = {
      primary: "btn-primary",
      secondary: "btn-secondary",
      danger: "btn-danger",
      outline: "border border-gray-300 text-gray-700 hover:bg-gray-50"
    }
    
    size_classes = {
      sm: "px-3 py-1 text-sm",
      md: "px-4 py-2 text-sm",
      lg: "px-6 py-3 text-base"
    }

    [
      base_classes,
      variant_classes[variant],
      size_classes[size],
      options[:class]
    ].compact.join(" ")
  end

  def html_options
    options.except(:class).merge(class: classes)
  end
end