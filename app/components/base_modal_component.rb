# Abstract base component for modal dialogs
class BaseModalComponent < ApplicationComponent
  def initialize(id:, title: nil, size: :medium, dismissible: true)
    @id = id
    @title = title
    @size = size
    @dismissible = dismissible
  end
  
  def call
    content_tag :div,
                id: @id,
                class: 'hidden fixed inset-0 z-50 overflow-y-auto',
                'aria-labelledby': "#{@id}-title",
                'aria-modal': true,
                role: 'dialog' do
      concat backdrop
      concat modal_container
    end
  end
  
  protected
  
  def backdrop
    content_tag :div, 
                nil,
                class: 'fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity',
                'aria-hidden': true,
                data: { action: @dismissible ? 'click->modal#close' : nil }.compact
  end
  
  def modal_container
    content_tag :div, class: 'flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0' do
      content_tag :div, class: modal_panel_classes do
        concat close_button if @dismissible
        concat modal_header if @title
        concat modal_body
        concat modal_footer if has_footer?
      end
    end
  end
  
  def modal_panel_classes
    base = 'relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 w-full'
    size_class = case @size
                 when :small then 'sm:max-w-sm'
                 when :large then 'sm:max-w-3xl'
                 when :xlarge then 'sm:max-w-5xl'
                 else 'sm:max-w-lg' # medium
                 end
    "#{base} #{size_class}"
  end
  
  def close_button
    content_tag :div, class: 'absolute top-0 right-0 pt-4 pr-4' do
      content_tag :button,
                  type: 'button',
                  class: 'rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2',
                  data: { action: 'click->modal#close' } do
        concat content_tag(:span, 'Close', class: 'sr-only')
        concat render(Ui::IconComponent.new(name: :x, size: 6))
      end
    end
  end
  
  def modal_header
    content_tag :div, class: 'bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4' do
      content_tag :h3, 
                  @title,
                  class: 'text-lg font-medium leading-6 text-gray-900',
                  id: "#{@id}-title"
    end
  end
  
  def modal_body
    content_tag :div, class: 'bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4' do
      render_body_content
    end
  end
  
  def modal_footer
    content_tag :div, class: 'bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6' do
      render_footer_content
    end
  end
  
  # Override in subclasses
  def render_body_content
    content
  end
  
  # Override in subclasses if footer is needed
  def render_footer_content
    nil
  end
  
  def has_footer?
    false # Override in subclasses that need a footer
  end
end