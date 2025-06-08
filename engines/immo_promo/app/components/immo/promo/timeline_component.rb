class Immo::Promo::TimelineComponent < ApplicationComponent
  def initialize(phases:, current_phase: nil)
    @phases = phases.respond_to?(:order) ? phases.order(:position) : phases
    @current_phase = current_phase
  end

  private

  attr_reader :phases, :current_phase
end