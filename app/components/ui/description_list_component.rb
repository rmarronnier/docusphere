class Ui::DescriptionListComponent < ApplicationComponent
  def initialize(title: nil)
    @title = title
    @items = []
  end
  
  def with_item(label:, value: nil, &block)
    @items << { label: label, value: value, block: block }
    self
  end

  private

  attr_reader :title, :items
end