class Ui::ModalComponent < ApplicationComponent
  renders_one :header
  renders_one :body
  renders_one :footer
  
  def initialize(id:, title: nil, size: :md, closable: true, backdrop_dismiss: true)
    @id = id
    @title = title
    @size = size.to_sym
    @closable = closable
    @backdrop_dismiss = backdrop_dismiss
  end

  private

  attr_reader :id, :title, :size, :closable, :backdrop_dismiss

  def modal_classes
    base_classes = "relative w-full max-h-full"
    
    size_classes = case size
    when :sm
      "max-w-md"
    when :lg
      "max-w-4xl"
    when :xl
      "max-w-6xl"
    when :full
      "max-w-full mx-4"
    else # :md
      "max-w-2xl"
    end

    "#{base_classes} #{size_classes}"
  end

  def backdrop_attrs
    attrs = {
      "data-modal-backdrop" => "static",
      "tabindex" => "-1",
      "aria-hidden" => "true",
      "class" => "hidden overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 justify-center items-center w-full md:inset-0 h-[calc(100%-1rem)] max-h-full bg-gray-900 bg-opacity-50"
    }
    
    if backdrop_dismiss
      attrs["data-modal-hide"] = id
    end
    
    attrs
  end
end