class Immo::Promo::Timeline::SummaryComponent < ApplicationComponent
  def initialize(phases:)
    @phases = phases
  end

  private

  attr_reader :phases

  def completed_count
    phases.where(status: 'completed').count
  end

  def in_progress_count
    phases.where(status: 'in_progress').count
  end

  def pending_count
    phases.where(status: 'pending').count
  end
end