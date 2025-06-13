class Ui::DataGridComponent::ColumnComponent < ApplicationComponent
  attr_reader :key, :label, :sortable, :width, :align, :format, :options, :content_block

  def initialize(key:, label:, sortable: false, width: nil, align: :left, format: nil, **options, &block)
    @key = key
    @label = label
    @sortable = sortable
    @width = width
    @align = align
    @format = format
    @options = options
    @content_block = block
  end

  def call
    # This component doesn't render anything itself
    # It's just a data container for the parent component
    nil
  end
  
  def render_cell(item)
    if content_block
      helpers.capture(item, &content_block)
    else
      nil
    end
  end
end