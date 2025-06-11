module Immo
  module Promo
    class TimeLog < ApplicationRecord
      self.table_name = 'immo_promo_time_logs'

      belongs_to :task, class_name: 'Immo::Promo::Task'
      belongs_to :user

      # Money attributes
      monetize :hourly_rate_cents, allow_nil: true

      # Aliases for test compatibility
      alias_attribute :work_date, :log_date
      alias_attribute :hours_spent, :hours
      alias_attribute :logged_date, :log_date

      validates :hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
      validates :log_date, presence: true
      validates :user_id, uniqueness: { scope: [ :task_id, :log_date ] }

      scope :for_period, ->(start_date, end_date) { where(log_date: start_date..end_date) }
      scope :for_date, ->(date) { where(log_date: date) }
      scope :for_user, ->(user) { where(user: user) }
      scope :this_week, -> { where(log_date: Date.current.beginning_of_week..Date.current.end_of_week) }
      scope :this_month, -> { where(log_date: Date.current.beginning_of_month..Date.current.end_of_month) }

      def project
        task.project
      end

      def phase
        task.phase
      end
      
      def billable_amount
        return Money.new(0) unless hourly_rate_cents.present? && hours.present?
        hourly_rate * hours
      end
    end
  end
end
