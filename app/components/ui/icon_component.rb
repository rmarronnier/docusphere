# frozen_string_literal: true

class Ui::IconComponent < ApplicationComponent
  def initialize(name:, size: 5, css_class: nil, viewbox: '0 0 24 24', stroke_width: 2)
    @name = name.to_sym
    @size = size
    @css_class = css_class
    @viewbox = viewbox
    @stroke_width = stroke_width
  end
  
  private
  
  def icon_path
    # Use the constant defined in initializer
    ::ICON_DEFINITIONS[@name]
  end
  
  def icon_classes
    base_classes = "h-#{@size} w-#{@size}"
    [@css_class, base_classes].compact.join(' ')
  end
end