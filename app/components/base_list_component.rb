# Abstract base component for rendering lists of items
class BaseListComponent < ApplicationComponent
  def initialize(items:, empty_message: nil, wrapper_class: nil)
    @items = items
    @empty_message = empty_message || default_empty_message
    @wrapper_class = wrapper_class || default_wrapper_class
  end
  
  def call
    if @items.any?
      content_tag :div, class: @wrapper_class do
        @items.map { |item| render_item(item) }.join.html_safe
      end
    else
      render_empty_state
    end
  end
  
  protected
  
  # Override in subclasses
  def render_item(item)
    raise NotImplementedError, "Subclasses must implement render_item"
  end
  
  # Override in subclasses to customize empty state
  def render_empty_state
    content_tag :div, class: 'text-center py-12' do
      content_tag :p, @empty_message, class: 'text-gray-500 text-sm'
    end
  end
  
  def default_empty_message
    'No items to display'
  end
  
  def default_wrapper_class
    'space-y-4'
  end
end