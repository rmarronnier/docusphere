class Immo::Promo::ProgressReport < ApplicationRecord
  self.table_name = 'immo_promo_progress_reports'
  
  belongs_to :project, class_name: 'Immo::Promo::Project'
  belongs_to :prepared_by, class_name: 'User'
  has_many_attached :photos
  has_many_attached :documents

  validates :report_date, presence: true
  validates :overall_progress, numericality: { in: 0..100 }, allow_nil: true

  scope :recent, -> { order(report_date: :desc) }
  scope :for_period, ->(start_date, end_date) { where(report_date: start_date..end_date) }

  def is_recent?
    report_date >= 1.week.ago
  end

  def has_issues?
    issues_risks.present?
  end
end