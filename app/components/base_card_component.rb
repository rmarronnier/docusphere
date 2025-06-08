# Abstract base component for card-style components
class BaseCardComponent < ApplicationComponent
  def initialize(padding: true, shadow: true, rounded: true, hover: false, border: false)
    @padding = padding
    @shadow = shadow
    @rounded = rounded
    @hover = hover
    @border = border
  end
  
  def call
    content_tag :div, class: card_classes do
      render_card_content
    end
  end
  
  protected
  
  # Override in subclasses
  def render_card_content
    content
  end
  
  def card_classes
    classes = ['bg-white']
    classes << 'p-6' if @padding
    classes << 'shadow' if @shadow
    classes << 'rounded-lg' if @rounded
    classes << 'hover:shadow-lg transition-shadow duration-200' if @hover
    classes << 'border border-gray-200' if @border
    
    classes.join(' ')
  end
  
  # Helper method for card headers
  def render_card_header(title: nil, actions: nil)
    return unless title || actions
    
    content_tag :div, class: 'flex items-center justify-between mb-4' do
      concat content_tag(:h3, title, class: 'text-lg font-medium text-gray-900') if title
      concat content_tag(:div, actions, class: 'flex items-center space-x-2') if actions
    end
  end
  
  # Helper method for card footers
  def render_card_footer(content)
    content_tag :div, content, class: 'mt-6 pt-6 border-t border-gray-200'
  end
end