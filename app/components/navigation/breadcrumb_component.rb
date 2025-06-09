class Navigation::BreadcrumbComponent < ApplicationComponent
  def initialize(items:)
    @items = items
  end

  private

  attr_reader :items
end