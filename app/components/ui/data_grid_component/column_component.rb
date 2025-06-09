class Ui::DataGridComponent::ColumnComponent < ApplicationComponent
  attr_reader :key, :label, :sortable, :width, :align, :format, :options

  def initialize(key:, label:, sortable: false, width: nil, align: :left, format: nil, **options)
    @key = key
    @label = label
    @sortable = sortable
    @width = width
    @align = align
    @format = format
    @options = options
  end

  def call
    # This component doesn't render anything itself
    # It's just a data container for the parent component
    nil
  end
end