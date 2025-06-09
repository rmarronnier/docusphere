class Layout::PageWrapperComponent < ApplicationComponent
  def initialize(max_width: "7xl", with_navbar: true)
    @max_width = max_width
    @with_navbar = with_navbar
  end

  private

  attr_reader :max_width, :with_navbar
  
  def container_classes
    "max-w-#{max_width} mx-auto py-6 sm:px-6 lg:px-8"
  end
end