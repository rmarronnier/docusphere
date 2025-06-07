module Schedulable
  extend ActiveSupport::Concern

  included do
    validates :start_date, presence: true, if: :schedule_required?
    validates :end_date, presence: true, if: :schedule_required?
    validate :end_date_after_start_date, if: :schedule_required?
    
    scope :current, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
    scope :upcoming, -> { where('start_date > ?', Time.current) }
    scope :past, -> { where('end_date < ?', Time.current) }
    scope :between_dates, ->(start_date, end_date) {
      where('start_date <= ? AND end_date >= ?', end_date, start_date)
    }
    scope :starting_between, ->(start_date, end_date) {
      where(start_date: start_date..end_date)
    }
    scope :ending_between, ->(start_date, end_date) {
      where(end_date: start_date..end_date)
    }
  end

  def duration
    return nil unless start_date && end_date
    end_date - start_date
  end

  def duration_in_days
    return nil unless duration
    (duration / 1.day).round
  end

  def duration_in_hours
    return nil unless duration
    (duration / 1.hour).round
  end

  def current?
    return false unless start_date && end_date
    Time.current.between?(start_date, end_date)
  end

  def upcoming?
    return false unless start_date
    start_date > Time.current
  end

  def past?
    return false unless end_date
    end_date < Time.current
  end

  def overlaps_with?(other_schedulable)
    return false unless other_schedulable.respond_to?(:start_date) && other_schedulable.respond_to?(:end_date)
    return false if start_date.blank? || end_date.blank? || other_schedulable.start_date.blank? || other_schedulable.end_date.blank?
    
    start_date <= other_schedulable.end_date && end_date >= other_schedulable.start_date
  end

  def progress_percentage
    return 0 unless start_date && end_date && current?
    
    total_duration = end_date - start_date
    elapsed_duration = Time.current - start_date
    
    ((elapsed_duration / total_duration) * 100).round(2)
  end

  def remaining_time
    return nil unless end_date
    return 0 if past?
    
    end_date - Time.current
  end

  def remaining_days
    return nil unless remaining_time
    (remaining_time / 1.day).round
  end

  private

  def schedule_required?
    true # Override in including models if needed
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'doit être postérieure à la date de début') if end_date < start_date
  end
end