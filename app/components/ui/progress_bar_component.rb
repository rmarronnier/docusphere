class Ui::ProgressBarComponent < ApplicationComponent
  def initialize(value:, max: 100, size: :medium, color: :auto, show_label: true, label_position: :right, label_text: nil)
    @value = value.to_i
    @max = max
    @percentage = calculate_percentage
    @size = size
    @color = color
    @show_label = show_label
    @label_position = label_position
    @label_text = label_text
  end
  
  private
  
  attr_reader :percentage, :size, :color, :show_label, :label_position
  
  def calculate_percentage
    return 0 if @max.zero?
    ((@value.to_f / @max) * 100).round
  end
  
  def label_text
    @label_text || content || 'Progress'
  end
  
  def bar_container_classes
    base = 'bg-gray-200 rounded-full overflow-hidden'
    case @size
    when :small
      "#{base} h-1.5"
    when :large
      "#{base} h-4"
    else # :medium
      "#{base} h-2"
    end
  end
  
  def bar_fill_classes
    base = 'h-full rounded-full'
    color_class = if @color == :auto
                    auto_color_class
                  else
                    explicit_color_class
                  end
    "#{base} #{color_class}"
  end
  
  def auto_color_class
    case @percentage
    when 0..25 then 'bg-red-600'
    when 26..50 then 'bg-yellow-600'
    when 51..75 then 'bg-blue-600'
    else 'bg-green-600'
    end
  end
  
  def explicit_color_class
    case @color
    when :red then 'bg-red-600'
    when :yellow then 'bg-yellow-600'
    when :blue then 'bg-blue-600'
    when :green then 'bg-green-600'
    when :gray then 'bg-gray-600'
    else 'bg-gray-600'
    end
  end
end