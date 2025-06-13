# Abstract base component for modal dialogs
class BaseModalComponent < ApplicationComponent
  def initialize(id:, title: nil, size: :medium, dismissible: true)
    @id = id
    @title = title
    @size = size
    @dismissible = dismissible
  end
  
  
  protected
  
  
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