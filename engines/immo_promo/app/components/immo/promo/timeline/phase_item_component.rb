class Immo::Promo::Timeline::PhaseItemComponent < ApplicationComponent
  def initialize(phase:, current_phase: nil, is_last: false)
    @phase = phase
    @current_phase = current_phase
    @is_last = is_last
  end

  private

  attr_reader :phase, :current_phase, :is_last
end