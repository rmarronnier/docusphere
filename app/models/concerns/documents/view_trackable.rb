# frozen_string_literal: true

module Documents
  module ViewTrackable
    extend ActiveSupport::Concern

    included do
      # Attributes for view tracking
      # These need to be added to the documents table:
      # - view_count :integer, default: 0
      # - last_viewed_at :datetime
      # - last_viewed_by_id :integer
      
      belongs_to :last_viewed_by, class_name: 'User', optional: true
      
      scope :recently_viewed, -> { where.not(last_viewed_at: nil).order(last_viewed_at: :desc) }
      scope :most_viewed, -> { order(view_count: :desc) }
      scope :viewed_since, ->(date) { where('last_viewed_at >= ?', date) }
      scope :never_viewed, -> { where(view_count: 0) }
    end

    # Increment view count and update last viewed timestamp
    def increment_view_count!(user = nil)
      self.class.transaction do
        self.view_count = (view_count || 0) + 1
        self.last_viewed_at = Time.current
        self.last_viewed_by = user if user
        save!(validate: false)
      end
    end

    # Increment download count
    def increment_download_count!(user = nil)
      self.class.transaction do
        self.download_count = (download_count || 0) + 1
        save!(validate: false)
      end
    end

    # Record a view without incrementing count (for background viewing)
    def touch_viewed_at!(user = nil)
      update_columns(
        last_viewed_at: Time.current,
        last_viewed_by_id: user&.id
      )
    end

    # Check if document was viewed recently
    def viewed_recently?(within: 24.hours)
      last_viewed_at.present? && last_viewed_at > within.ago
    end

    # Get viewers count (unique users who viewed the document)
    def unique_viewers_count
      # This would require a separate tracking table for detailed analytics
      # For now, we can estimate based on audits
      audits.where(action: 'view').distinct.count(:user_id)
    rescue
      # If audits table doesn't track views, return nil
      nil
    end

    # Get view statistics
    def view_statistics
      {
        total_views: view_count || 0,
        last_viewed_at: last_viewed_at,
        last_viewed_by: last_viewed_by&.display_name,
        viewed_today: last_viewed_at&.today? || false,
        days_since_last_view: last_viewed_at ? (Date.current - last_viewed_at.to_date).to_i : nil
      }
    end
  end
end