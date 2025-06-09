class Layout::CardGridComponent < ApplicationComponent
  def initialize(columns: { sm: 2, lg: 3, xl: 4 }, gap: 4)
    @columns = columns
    @gap = gap
  end

  private

  attr_reader :columns, :gap
  
  def grid_classes
    classes = ["grid", "grid-cols-1", "gap-#{gap}"]
    
    classes << "sm:grid-cols-#{columns[:sm]}" if columns[:sm]
    classes << "lg:grid-cols-#{columns[:lg]}" if columns[:lg]
    classes << "xl:grid-cols-#{columns[:xl]}" if columns[:xl]
    
    classes.join(" ")
  end
end