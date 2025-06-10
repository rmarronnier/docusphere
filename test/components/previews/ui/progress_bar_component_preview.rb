# @label Progress Bar Component
class Ui::ProgressBarComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Progress Bar
  def default
    render Ui::ProgressBarComponent.new(value: 50, max: 100)
  end
  
  # @label Different Progress Values
  def progress_values
    content_tag :div, class: "space-y-6" do
      [
        content_tag(:div) do
          [
            content_tag(:label, "Début (15%)", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 15, max: 100))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:label, "Moitié (50%)", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 50, max: 100))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:label, "Presque fini (85%)", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 85, max: 100))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:label, "Terminé (100%)", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 100, max: 100))
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
  
  # @label Different Sizes
  def sizes
    content_tag :div, class: "space-y-6" do
      [
        content_tag(:div) do
          [
            content_tag(:label, "Petite", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 60, max: 100, size: "sm"))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:label, "Normale", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 60, max: 100, size: "md"))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:label, "Grande", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 60, max: 100, size: "lg"))
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
  
  # @label With Labels
  def with_labels
    content_tag :div, class: "space-y-6" do
      [
        content_tag(:div) do
          [
            content_tag(:label, "Téléchargement en cours", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 35, max: 100, label: "35% terminé"))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:label, "Installation", class: "block text-sm font-medium mb-2"),
            render(Ui::ProgressBarComponent.new(value: 80, max: 100, label: "4 sur 5 étapes"))
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
end