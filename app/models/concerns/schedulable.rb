module Schedulable
  extend ActiveSupport::Concern

  class_methods do
    def schedulable_with(start_date: :start_date, end_date: :end_date)
      # Store the field mappings
      class_attribute :schedulable_start_field, :schedulable_end_field
      self.schedulable_start_field = start_date
      self.schedulable_end_field = end_date
      
      # Define alias methods if needed
      if start_date != :start_date
        alias_method :start_date, start_date
        alias_method :start_date=, "#{start_date}="
      end
      
      if end_date != :end_date
        alias_method :end_date, end_date
        alias_method :end_date=, "#{end_date}="
      end
      
      # Add validations
      validates start_date, presence: true, if: :schedule_required?
      validates end_date, presence: true, if: :schedule_required?
      validate :end_date_after_start_date, if: :schedule_required?
      
      # Add scopes using the actual field names
      scope :current, -> { 
        where("#{table_name}.#{schedulable_start_field} <= ? AND #{table_name}.#{schedulable_end_field} >= ?", Time.current, Time.current) 
      }
      scope :upcoming, -> { 
        where("#{table_name}.#{schedulable_start_field} > ?", Time.current) 
      }
      scope :past, -> { 
        where("#{table_name}.#{schedulable_end_field} < ?", Time.current) 
      }
      scope :between_dates, ->(start_date, end_date) {
        where("#{table_name}.#{schedulable_start_field} <= ? AND #{table_name}.#{schedulable_end_field} >= ?", end_date, start_date)
      }
      scope :starting_between, ->(start_date, end_date) {
        where(schedulable_start_field => start_date..end_date)
      }
      scope :ending_between, ->(start_date, end_date) {
        where(schedulable_end_field => start_date..end_date)
      }
    end
  end

  included do
    # Default configuration - can be overridden by calling schedulable_with
    schedulable_with unless respond_to?(:schedulable_start_field)
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