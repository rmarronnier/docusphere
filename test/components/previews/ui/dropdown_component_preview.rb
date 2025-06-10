# @label Dropdown Component
class Ui::DropdownComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Dropdown
  def default
    render Ui::DropdownComponent.new(label: "Actions") do |dropdown|
      dropdown.with_item(text: "Voir", href: "#", icon: "eye")
      dropdown.with_item(text: "Modifier", href: "#", icon: "edit")
      dropdown.with_item(text: "Supprimer", href: "#", icon: "delete", method: "delete")
    end
  end
  
  # @label Dropdown Variants
  def variants
    content_tag :div, class: "space-x-4 flex" do
      [
        render(Ui::DropdownComponent.new(label: "Primary", variant: "primary")) do |dropdown|
          dropdown.with_item(text: "Option 1", href: "#")
          dropdown.with_item(text: "Option 2", href: "#")
        end,
        render(Ui::DropdownComponent.new(label: "Secondary", variant: "secondary")) do |dropdown|
          dropdown.with_item(text: "Option 1", href: "#")
          dropdown.with_item(text: "Option 2", href: "#")
        end,
        render(Ui::DropdownComponent.new(label: "Outline", variant: "outline")) do |dropdown|
          dropdown.with_item(text: "Option 1", href: "#")
          dropdown.with_item(text: "Option 2", href: "#")
        end
      ].join.html_safe
    end
  end
  
  # @label With Icons and Dividers
  def with_icons_and_dividers
    render Ui::DropdownComponent.new(label: "Menu Complet", icon: "menu") do |dropdown|
      dropdown.with_item(text: "Profil", href: "#", icon: "user")
      dropdown.with_item(text: "Paramètres", href: "#", icon: "settings")
      dropdown.with_divider
      dropdown.with_item(text: "Aide", href: "#", icon: "help")
      dropdown.with_item(text: "À propos", href: "#", icon: "info")
      dropdown.with_divider
      dropdown.with_item(text: "Déconnexion", href: "#", icon: "logout", method: "delete")
    end
  end
  
  # @label Different Sizes
  def sizes
    content_tag :div, class: "space-x-4 flex items-center" do
      [
        render(Ui::DropdownComponent.new(label: "Small", size: "sm")) do |dropdown|
          dropdown.with_item(text: "Option 1", href: "#")
          dropdown.with_item(text: "Option 2", href: "#")
        end,
        render(Ui::DropdownComponent.new(label: "Medium", size: "md")) do |dropdown|
          dropdown.with_item(text: "Option 1", href: "#")
          dropdown.with_item(text: "Option 2", href: "#")
        end,
        render(Ui::DropdownComponent.new(label: "Large", size: "lg")) do |dropdown|
          dropdown.with_item(text: "Option 1", href: "#")
          dropdown.with_item(text: "Option 2", href: "#")
        end
      ].join.html_safe
    end
  end
  
  # @label Dropdown Positions
  def positions
    content_tag :div, class: "grid grid-cols-2 gap-8 p-8" do
      [
        content_tag(:div) do
          [
            content_tag(:h3, "Dropdown Left", class: "mb-4 font-semibold"),
            render(Ui::DropdownComponent.new(label: "Left Aligned", position: "left")) do |dropdown|
              dropdown.with_item(text: "Option 1", href: "#")
              dropdown.with_item(text: "Option 2", href: "#")
              dropdown.with_item(text: "Option 3", href: "#")
            end
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:h3, "Dropdown Right", class: "mb-4 font-semibold"),
            render(Ui::DropdownComponent.new(label: "Right Aligned", position: "right")) do |dropdown|
              dropdown.with_item(text: "Option 1", href: "#")
              dropdown.with_item(text: "Option 2", href: "#")
              dropdown.with_item(text: "Option 3", href: "#")
            end
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
end