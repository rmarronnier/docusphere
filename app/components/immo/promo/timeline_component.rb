class Immo::Promo::TimelineComponent < ApplicationComponent
  def initialize(phases:, current_phase: nil)
    @phases = phases.order(:position)
    @current_phase = current_phase
  end

  private

  attr_reader :phases, :current_phase

  def phase_status_class(phase)
    case phase.status
    when 'completed' then 'bg-green-600'
    when 'in_progress' then 'bg-blue-600'
    when 'delayed' then 'bg-red-600'
    else 'bg-gray-300'
    end
  end

  def phase_icon(phase)
    case phase.phase_type
    when 'studies' then 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'
    when 'permits' then 'M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z'
    when 'construction' then 'M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547A1.998 1.998 0 004 17.658V18a2 2 0 002 2h12a2 2 0 002-2v-.342a1.998 1.998 0 00-.572-1.43z'
    when 'reception' then 'M5 13l4 4L19 7'
    when 'delivery' then 'M3 3h2l.4 2M7 13h10l4-8H5.4m-2.4 0L4.6 3M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17M17 13v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6'
    else 'M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'
    end
  end

  def is_current_phase?(phase)
    current_phase && current_phase.id == phase.id
  end

  def formatted_duration(phase)
    return 'À définir' unless phase.start_date && phase.end_date
    
    duration = (phase.end_date.to_date - phase.start_date.to_date).to_i
    case duration
    when 0..6 then "#{duration + 1} jour#{'s' if duration > 0}"
    when 7..29 then "#{(duration / 7.0).round} semaine#{'s' if duration > 6}"
    else "#{(duration / 30.0).round} mois"
    end
  end

  def phase_progress_width(phase)
    "#{phase.completion_percentage}%"
  end
end