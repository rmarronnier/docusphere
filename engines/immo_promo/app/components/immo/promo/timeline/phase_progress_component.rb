class Immo::Promo::Timeline::PhaseProgressComponent < ApplicationComponent
  def initialize(phase:)
    @phase = phase
  end

  private

  attr_reader :phase

  def phase_progress_color
    case phase.status
    when 'completed' then :green
    when 'in_progress' then :blue
    when 'delayed' then :red
    else :gray
    end
  end
end