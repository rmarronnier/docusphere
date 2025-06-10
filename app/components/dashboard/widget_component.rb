class Dashboard::WidgetComponent < ApplicationComponent
  attr_reader :widget_data, :size, :loading, :error
  
  def initialize(widget_data:, size: { width: 1, height: 1 }, loading: false, error: nil)
    @widget_data = widget_data
    @size = size
    @loading = loading
    @error = error
  end
  
  private
  
  def widget_classes
    classes = ['dashboard-widget', 'bg-white', 'rounded-lg', 'shadow', 'p-4', 'relative']
    classes << "col-span-#{size[:width]}" if size[:width] > 1
    classes << "row-span-#{size[:height]}" if size[:height] > 1
    classes << 'animate-pulse' if loading
    classes << 'border-red-300' if error
    classes.join(' ')
  end
  
  def render_header?
    widget_data[:title].present? || widget_data[:actions].present?
  end
  
  def render_actions?
    widget_data[:actions].present? && !loading && !error
  end
end