module Immo
  module Promo
    class TimeLog < ApplicationRecord
      self.table_name = 'immo_promo_time_logs'

      belongs_to :task, class_name: 'Immo::Promo::Task'
      belongs_to :user

      validates :hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
      validates :logged_date, presence: true
      validates :user_id, uniqueness: { scope: [ :task_id, :logged_date ] }

      scope :for_period, ->(start_date, end_date) { where(logged_date: start_date..end_date) }
      scope :for_user, ->(user) { where(user: user) }
      scope :this_week, -> { where(logged_date: Date.current.beginning_of_week..Date.current.end_of_week) }
      scope :this_month, -> { where(logged_date: Date.current.beginning_of_month..Date.current.end_of_month) }

      def project
        task.project
      end

      def phase
        task.phase
      end
      
      # Alias for compatibility
      alias_attribute :log_date, :logged_date
    end
  end
end
