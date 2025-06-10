# Concern for handling component theming and styling
module Themeable
  extend ActiveSupport::Concern

  # Color schemes for consistent theming
  THEME_COLORS = {
    primary: {
      bg: 'bg-indigo-600',
      text: 'text-white',
      hover: 'hover:bg-indigo-700',
      focus: 'focus:ring-indigo-500',
      light: 'bg-indigo-100',
      light_text: 'text-indigo-800'
    },
    secondary: {
      bg: 'bg-gray-600',
      text: 'text-white',
      hover: 'hover:bg-gray-700',
      focus: 'focus:ring-gray-500',
      light: 'bg-gray-100',
      light_text: 'text-gray-800'
    },
    success: {
      bg: 'bg-green-600',
      text: 'text-white',
      hover: 'hover:bg-green-700',
      focus: 'focus:ring-green-500',
      light: 'bg-green-100',
      light_text: 'text-green-800'
    },
    danger: {
      bg: 'bg-red-600',
      text: 'text-white',
      hover: 'hover:bg-red-700',
      focus: 'focus:ring-red-500',
      light: 'bg-red-100',
      light_text: 'text-red-800'
    },
    warning: {
      bg: 'bg-yellow-500',
      text: 'text-black',
      hover: 'hover:bg-yellow-600',
      focus: 'focus:ring-yellow-500',
      light: 'bg-yellow-100',
      light_text: 'text-yellow-800'
    },
    info: {
      bg: 'bg-blue-600',
      text: 'text-white',
      hover: 'hover:bg-blue-700',
      focus: 'focus:ring-blue-500',
      light: 'bg-blue-100',
      light_text: 'text-blue-800'
    }
  }.freeze

  # Size variants
  SIZES = {
    xs: {
      text: 'text-xs',
      padding: 'px-2 py-1',
      gap: 'gap-1'
    },
    sm: {
      text: 'text-sm',
      padding: 'px-3 py-1.5',
      gap: 'gap-1.5'
    },
    default: {
      text: 'text-base',
      padding: 'px-4 py-2',
      gap: 'gap-2'
    },
    lg: {
      text: 'text-lg',
      padding: 'px-6 py-3',
      gap: 'gap-3'
    },
    xl: {
      text: 'text-xl',
      padding: 'px-8 py-4',
      gap: 'gap-4'
    }
  }.freeze

  included do
    attr_reader :theme, :size, :variant
  end

  # Get theme colors
  def theme_colors(variant = :default)
    colors = THEME_COLORS[@theme] || THEME_COLORS[:primary]
    
    case variant
    when :light
      {
        bg: colors[:light],
        text: colors[:light_text]
      }
    when :outline
      {
        bg: 'bg-transparent',
        text: colors[:light_text],
        border: "border-2 border-#{@theme}-600"
      }
    else
      colors
    end
  end

  # Get size classes
  def size_classes
    SIZES[@size] || SIZES[:default]
  end

  # Build classes for themed components
  def themed_classes(*additional_classes)
    colors = theme_colors(@variant)
    size = size_classes
    
    base_classes = [colors[:bg], colors[:text], size[:text], size[:padding]]
    base_classes << colors[:border] if colors[:border]
    base_classes << colors[:hover] if colors[:hover] && @variant != :light
    
    (base_classes + additional_classes).compact.join(' ')
  end

  # Get color by name (for dynamic colors)
  def color_class(color, type = 'bg', intensity = 500)
    "#{type}-#{color}-#{intensity}"
  end

  # Merge custom classes with theme classes
  def merge_classes(theme_classes, custom_classes)
    return theme_classes if custom_classes.blank?
    
    # Parse classes to avoid duplicates
    theme_set = theme_classes.split(' ').to_set
    custom_set = custom_classes.split(' ').to_set
    
    # Remove conflicting classes
    prefixes = %w[bg- text- border- hover: focus: px- py- p- m-]
    
    custom_set.each do |custom_class|
      prefix = prefixes.find { |p| custom_class.start_with?(p) }
      next unless prefix
      
      theme_set.reject! { |theme_class| theme_class.start_with?(prefix) }
    end
    
    (theme_set + custom_set).to_a.join(' ')
  end

  class_methods do
    # Define available themes for a component
    def available_themes(*themes)
      const_set(:AVAILABLE_THEMES, themes)
      
      define_method :validate_theme do
        available = self.class::AVAILABLE_THEMES
        unless available.include?(@theme)
          @theme = available.first
        end
      end
    end

    # Define available sizes for a component
    def available_sizes(*sizes)
      const_set(:AVAILABLE_SIZES, sizes)
      
      define_method :validate_size do
        available = self.class::AVAILABLE_SIZES
        unless available.include?(@size)
          @size = :default
        end
      end
    end
  end
end