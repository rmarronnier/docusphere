class Ui::DataGridComponent::EmptyStateComponent < ApplicationComponent
  attr_reader :message, :icon, :show_icon, :custom_content

  def initialize(
    message: "Aucune donnée disponible",
    icon: "document",
    show_icon: true,
    custom_content: nil
  )
    @message = message
    @icon = icon
    @show_icon = show_icon
    @custom_content = custom_content
  end


  private

end