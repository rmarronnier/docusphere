class Immo::Promo::ProjectCardComponent < ApplicationComponent
  def initialize(project:, show_actions: true, show_financial: true, show_thumbnail: true, variant: :default)
    @project = project
    @show_actions = show_actions
    @show_financial = show_financial
    @show_thumbnail = show_thumbnail
    @variant = variant
  end

  private

  attr_reader :project, :show_actions, :show_financial, :show_thumbnail, :variant

  def compact_layout?
    variant == :compact
  end

  def detailed_layout?
    variant == :detailed
  end

  def card_classes
    base_classes = "bg-white overflow-hidden shadow rounded-lg hover:shadow-lg transition-shadow duration-200"
    
    case variant
    when :compact
      "#{base_classes} hover:shadow-md"
    when :detailed
      "#{base_classes} hover:shadow-xl"
    else
      base_classes
    end
  end

  def card_padding_classes
    case variant
    when :compact
      "p-4"
    when :detailed
      "p-8"
    else
      "p-6"
    end
  end
end