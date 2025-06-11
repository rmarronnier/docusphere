# frozen_string_literal: true

module Documents
  module Shareable
    extend ActiveSupport::Concern

    included do
      has_many :shares, as: :shareable, dependent: :destroy
      has_many :document_shares, dependent: :destroy
    end

    # Check if document is shared with a specific user
    def shared_with?(user)
      return false unless user
      document_shares.where(shared_with: user, is_active: true).exists?
    end

    # Share document with a user
    def share_with!(user, access_level: 'read', expires_at: nil, shared_by: nil)
      document_shares.create!(
        shared_with: user,
        shared_by: shared_by || Current.user,
        access_level: access_level,
        expires_at: expires_at
      )
    end

    # Get all users with access to this document
    def users_with_access
      users = [uploaded_by]
      users += document_shares.active.includes(:shared_with).map(&:shared_with)
      users += space.users if space
      users.compact.uniq
    end
  end
end