class Immo::Promo::ProjectCardComponent < ApplicationComponent
  def initialize(project:, show_actions: true, variant: :default)
    @project = project
    @show_actions = show_actions
    @variant = variant
  end

  private

  attr_reader :project, :show_actions, :variant
end