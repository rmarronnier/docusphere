# frozen_string_literal: true

module Documents
  module ActivityTrackable
    extend ActiveSupport::Concern

    # Track when a user views the document
    def track_view!(user)
      increment!(:view_count)
      # Could also create an activity record here
    end

    # Track when a user downloads the document
    def track_download!(user)
      increment!(:download_count)
      # Could also create an activity record here
    end
  end
end