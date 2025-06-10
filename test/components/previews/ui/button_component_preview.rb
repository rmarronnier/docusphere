# @label Button Component
class Ui::ButtonComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Button
  def default
    render Ui::ButtonComponent.new(text: "Cliquez-moi")
  end
  
  # @label All Variants  
  def variants
    content_tag :div, class: "space-x-2" do
      [
        render(Ui::ButtonComponent.new(text: "Primary", variant: :primary)),
        render(Ui::ButtonComponent.new(text: "Secondary", variant: :secondary)),
        render(Ui::ButtonComponent.new(text: "Success", variant: :success)),
        render(Ui::ButtonComponent.new(text: "Danger", variant: :danger)),
        render(Ui::ButtonComponent.new(text: "Warning", variant: :warning)),
        render(Ui::ButtonComponent.new(text: "Info", variant: :info))
      ].map(&:to_s).join.html_safe
    end
  end
  
  # @label Sizes
  def sizes
    content_tag :div, class: "space-y-4" do
      content_tag(:div, class: "flex items-center space-x-2") do
        [
          render(Ui::ButtonComponent.new(text: "Extra Small", size: "xs")),
          render(Ui::ButtonComponent.new(text: "Small", size: "sm")),
          render(Ui::ButtonComponent.new(text: "Medium", size: "md")),
          render(Ui::ButtonComponent.new(text: "Large", size: "lg")),
          render(Ui::ButtonComponent.new(text: "Extra Large", size: "xl"))
        ].map(&:to_s).join.html_safe
      end
    end
  end
  
  # @label With Icons
  def with_icons
    content_tag :div, class: "space-y-4" do
      content_tag(:div, class: "space-x-2") do
        [
          render(Ui::ButtonComponent.new(text: "Télécharger", icon: "download", variant: :primary)),
          render(Ui::ButtonComponent.new(text: "Enregistrer", icon: "save", variant: :success)),
          render(Ui::ButtonComponent.new(text: "Supprimer", icon: "trash", variant: :danger)),
          render(Ui::ButtonComponent.new(text: "Modifier", icon: "edit", variant: :secondary))
        ].map(&:to_s).join.html_safe
      end
    end
  end
  
  # @label States
  def states
    content_tag :div, class: "space-y-4" do
[
        content_tag(:h3, "Normal", class: "text-sm font-medium text-gray-700"),
        content_tag(:div, class: "space-x-2") do
          [
            render(Ui::ButtonComponent.new(text: "Enabled", variant: :primary)),
            render(Ui::ButtonComponent.new(text: "Disabled", variant: :primary, disabled: true)),
            render(Ui::ButtonComponent.new(text: "Loading", variant: :primary, loading: true))
          ].map(&:to_s).join.html_safe
        end
      ].map(&:to_s).join.html_safe
    end
  end
  
  # @label Full Width
  def full_width
    content_tag :div, class: "max-w-md" do
[
        render(Ui::ButtonComponent.new(text: "Bouton pleine largeur", variant: :primary, full_width: true)),
        content_tag(:div, class: "mt-2"),
        render(Ui::ButtonComponent.new(text: "Autre bouton pleine largeur", variant: :secondary, full_width: true))
      ].map(&:to_s).join.html_safe
    end
  end
  
  # @label Button as Link
  def as_link
    content_tag :div, class: "space-x-2" do
[
        render(Ui::ButtonComponent.new(text: "Lien interne", href: "/documents")),
        render(Ui::ButtonComponent.new(text: "Lien externe", href: "https://example.com", target: "_blank", variant: :secondary))
      ].map(&:to_s).join.html_safe
    end
  end
  
  # @label With Custom Classes
  def custom_classes
    render Ui::ButtonComponent.new(
      text: "Bouton personnalisé",
      variant: :primary,
      class: "shadow-lg transform hover:scale-105 transition-transform"
    )
  end
  
  # @label Button Group Example
  def button_group
    content_tag :div, class: "inline-flex rounded-md shadow-sm" do
[
        render(Ui::ButtonComponent.new(text: "Gauche", variant: :secondary, class: "rounded-r-none")),
        render(Ui::ButtonComponent.new(text: "Centre", variant: :secondary, class: "rounded-none border-l-0")),
        render(Ui::ButtonComponent.new(text: "Droite", variant: :secondary, class: "rounded-l-none border-l-0"))
      ].map(&:to_s).join.html_safe
    end
  end
end