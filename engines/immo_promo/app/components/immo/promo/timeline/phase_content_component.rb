class Immo::Promo::Timeline::PhaseContentComponent < ApplicationComponent
  def initialize(phase:, current_phase: nil)
    @phase = phase
    @current_phase = current_phase
  end

  private

  attr_reader :phase, :current_phase

  def is_current_phase?
    current_phase && current_phase.id == phase.id
  end

  def formatted_duration
    return 'Dates non définies' unless phase.start_date && phase.end_date
    
    duration = (phase.end_date.to_date - phase.start_date.to_date).to_i
    case duration
    when 0..6 then "#{duration + 1} jour#{'s' if duration > 0}"
    when 7..29 then "#{(duration / 7.0).round} semaine#{'s' if duration > 6}"
    else "#{(duration / 30.0).round} mois"
    end
  end

  def formatted_start_date
    phase.start_date&.strftime('%d/%m/%Y') || 'Dates non définies'
  end

  def formatted_end_date
    phase.end_date&.strftime('%d/%m/%Y') || 'Dates non définies'
  end
  
  def has_dates?
    phase.start_date.present? || phase.end_date.present?
  end
end