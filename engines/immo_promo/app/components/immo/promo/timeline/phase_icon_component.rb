class Immo::Promo::Timeline::PhaseIconComponent < ApplicationComponent
  def initialize(phase:)
    @phase = phase
  end

  private

  attr_reader :phase

  def phase_status_class
    case phase.status
    when 'completed' then 'bg-green-600'
    when 'in_progress' then 'bg-blue-600'
    when 'delayed' then 'bg-red-600'
    else 'bg-gray-300'
    end
  end

  def phase_icon_name
    case phase.phase_type
    when 'studies' then :document
    when 'permits' then :badge_check
    when 'construction' then :construction
    when 'reception' then :check
    when 'delivery' then :shopping_cart
    else :clipboard
    end
  end
end