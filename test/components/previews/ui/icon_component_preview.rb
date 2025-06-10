# @label Icon Component
class Ui::IconComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Icon
  def default
    render Ui::IconComponent.new(name: "document")
  end
  
  # @label Icon Sizes
  def sizes
    content_tag :div, class: "space-y-4" do
      [
        content_tag(:div, class: "flex items-center space-x-4") do
          [
            content_tag(:div, [
              render(Ui::IconComponent.new(name: "document", size: 3)),
              content_tag(:span, "Size 3", class: "ml-2")
            ].join.html_safe, class: "flex items-center"),
            content_tag(:div, [
              render(Ui::IconComponent.new(name: "document", size: 4)),
              content_tag(:span, "Size 4", class: "ml-2")
            ].join.html_safe, class: "flex items-center"),
            content_tag(:div, [
              render(Ui::IconComponent.new(name: "document", size: 6)),
              content_tag(:span, "Size 6", class: "ml-2")
            ].join.html_safe, class: "flex items-center"),
            content_tag(:div, [
              render(Ui::IconComponent.new(name: "document", size: 8)),
              content_tag(:span, "Size 8", class: "ml-2")
            ].join.html_safe, class: "flex items-center")
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
  
  # @label Common Icons
  def common_icons
    content_tag :div, class: "grid grid-cols-6 gap-4" do
      icons = %w[document folder user search settings home upload download edit delete]
      icons.map do |icon_name|
        content_tag(:div, class: "flex flex-col items-center p-4 border rounded") do
          [
            render(Ui::IconComponent.new(name: icon_name, size: 6)),
            content_tag(:span, icon_name, class: "mt-2 text-sm")
          ].join.html_safe
        end
      end.join.html_safe
    end
  end
  
  # @label Icon Colors
  def icon_colors
    content_tag :div, class: "space-x-4 flex items-center" do
      [
        render(Ui::IconComponent.new(name: "document", size: 6, css_class: "text-blue-500")),
        render(Ui::IconComponent.new(name: "document", size: 6, css_class: "text-red-500")),
        render(Ui::IconComponent.new(name: "document", size: 6, css_class: "text-green-500")),
        render(Ui::IconComponent.new(name: "document", size: 6, css_class: "text-yellow-500")),
        render(Ui::IconComponent.new(name: "document", size: 6, css_class: "text-purple-500"))
      ].join.html_safe
    end
  end
end