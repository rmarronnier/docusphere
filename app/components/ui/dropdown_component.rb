class Ui::DropdownComponent < ApplicationComponent
  def initialize(trigger_text: nil, trigger_icon: nil, position: "right")
    @trigger_text = trigger_text
    @trigger_icon = trigger_icon
    @position = position
  end

  private

  attr_reader :trigger_text, :trigger_icon, :position
  
  def menu_position_classes
    case position
    when "left"
      "left-0"
    when "center"
      "left-1/2 transform -translate-x-1/2"
    else
      "right-0"
    end
  end
  
  def default_trigger_icon
    '<path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z"/>'
  end
end