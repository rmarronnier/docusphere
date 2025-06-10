class Immo::Promo::Timeline::SummaryComponent < ApplicationComponent
  def initialize(phases:)
    @phases = phases
  end

  private

  attr_reader :phases

  def completed_count
    phases.count { |phase| phase.status == 'completed' }
  end

  def in_progress_count
    phases.count { |phase| phase.status == 'in_progress' }
  end

  def pending_count
    phases.count { |phase| phase.status == 'pending' }
  end
end