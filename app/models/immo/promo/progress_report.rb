class Immo::Promo::ProgressReport < ApplicationRecord
  self.table_name = 'immo_promo_progress_reports'
  
  belongs_to :project, class_name: 'Immo::Promo::Project'
  belongs_to :created_by, class_name: 'User'
  has_many_attached :photos
  has_many_attached :documents

  validates :report_date, presence: true
  validates :report_type, inclusion: { in: %w[weekly monthly milestone phase_completion quality_control] }
  validates :overall_progress_percentage, numericality: { in: 0..100 }

  enum report_type: {
    weekly: 'weekly',
    monthly: 'monthly',
    milestone: 'milestone',
    phase_completion: 'phase_completion',
    quality_control: 'quality_control'
  }

  scope :recent, -> { order(report_date: :desc) }
  scope :by_type, ->(type) { where(report_type: type) }
  scope :for_period, ->(start_date, end_date) { where(report_date: start_date..end_date) }

  def is_recent?
    report_date >= 1.week.ago
  end

  def has_issues?
    issues.present?
  end

  def has_delays?
    delays.present?
  end

  def weather_impact?
    weather_conditions.present? && weather_conditions.include?('rain') || weather_conditions.include?('snow')
  end
end