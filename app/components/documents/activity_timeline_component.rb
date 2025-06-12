# frozen_string_literal: true

module Documents
  class ActivityTimelineComponent < ViewComponent::Base
    include ApplicationHelper
    
    def initialize(document:, limit: 20, show_filters: true)
      @document = document
      @limit = limit
      @show_filters = show_filters
    end

    private

    attr_reader :document, :limit, :show_filters

    def activities
      @activities ||= fetch_activities
    end

    def fetch_activities
      # Combine different activity sources
      all_activities = []
      
      # Document audits (creation, updates, etc.)
      all_activities.concat(document_audits)
      
      # Validation activities
      all_activities.concat(validation_activities)
      
      # Version activities
      all_activities.concat(version_activities)
      
      # Share activities
      all_activities.concat(share_activities)
      
      # Download activities
      all_activities.concat(download_activities)
      
      # Comment activities
      all_activities.concat(comment_activities)
      
      # Sort by timestamp and limit
      all_activities.sort_by(&:timestamp).reverse.first(limit)
    end

    def document_audits
      document.audits.map do |audit|
        ActivityItem.new(
          type: audit_type(audit),
          action: audit.action,
          user: audit.user,
          timestamp: audit.created_at,
          details: audit_details(audit),
          icon: audit_icon(audit),
          color: audit_color(audit)
        )
      end
    end

    def validation_activities
      document.validation_requests.includes(:requester, :document_validations).flat_map do |request|
        activities = []
        
        # Request creation
        activities << ActivityItem.new(
          type: 'validation_requested',
          action: 'requested validation',
          user: request.requester,
          timestamp: request.created_at,
          details: { validation_type: request.validation_type, deadline: request.deadline },
          icon: 'clipboard-document-check',
          color: 'purple'
        )
        
        # Validations
        request.document_validations.each do |validation|
          activities << ActivityItem.new(
            type: "validation_#{validation.status}",
            action: "#{validation.status} validation",
            user: validation.validator,
            timestamp: validation.created_at,
            details: { comment: validation.comment },
            icon: validation_icon(validation.status),
            color: validation_color(validation.status)
          )
        end
        
        activities
      end
    end

    def version_activities
      return [] unless document.versions.any?
      
      document.versions.map do |version|
        ActivityItem.new(
          type: 'version_created',
          action: 'created new version',
          user: version.whodunnit_user,
          timestamp: version.created_at,
          details: { 
            version_number: version.index + 1,
            changes: version.changeset&.keys || []
          },
          icon: 'document-duplicate',
          color: 'blue'
        )
      end
    end

    def share_activities
      document.document_shares.includes(:shared_by, :shared_with).map do |share|
        ActivityItem.new(
          type: 'document_shared',
          action: 'shared document',
          user: share.shared_by,
          timestamp: share.created_at,
          details: {
            shared_with: share.shared_with&.full_name || share.shared_with_email,
            permissions: share.permissions,
            expires_at: share.expires_at
          },
          icon: 'share',
          color: 'green'
        )
      end
    end

    def download_activities
      # This would come from a download tracking table
      # For now, we'll return an empty array
      []
    end

    def comment_activities
      # This would come from a comments table
      # For now, we'll return an empty array
      []
    end

    # Helper methods for audit activities
    def audit_type(audit)
      case audit.action
      when 'create' then 'document_created'
      when 'update' then 'document_updated'
      when 'destroy' then 'document_deleted'
      else audit.action
      end
    end

    def audit_details(audit)
      details = {}
      
      if audit.action == 'update' && audit.audited_changes.present?
        details[:changes] = format_changes(audit.audited_changes)
      end
      
      details
    end

    def format_changes(changes)
      changes.map do |field, values|
        next if field.in?(['updated_at', 'lock_version'])
        
        {
          field: field.humanize,
          from: format_value(values[0]),
          to: format_value(values[1])
        }
      end.compact
    end

    def format_value(value)
      case value
      when true then 'Yes'
      when false then 'No'
      when nil then 'None'
      when Time, DateTime then value.to_fs(:short)
      else value.to_s.truncate(50)
      end
    end

    def audit_icon(audit)
      case audit.action
      when 'create' then 'plus-circle'
      when 'update' then 'pencil'
      when 'destroy' then 'trash'
      else 'information-circle'
      end
    end

    def audit_color(audit)
      case audit.action
      when 'create' then 'green'
      when 'update' then 'blue'
      when 'destroy' then 'red'
      else 'gray'
      end
    end

    def validation_icon(status)
      case status
      when 'approved', 'validated' then 'check-circle'
      when 'rejected' then 'x-circle'
      when 'pending' then 'clock'
      else 'question-mark-circle'
      end
    end

    def validation_color(status)
      case status
      when 'approved', 'validated' then 'green'
      when 'rejected' then 'red'
      when 'pending' then 'yellow'
      else 'gray'
      end
    end

    def activity_filters
      [
        { id: 'all', label: 'All Activities', count: activities.count },
        { id: 'updates', label: 'Updates', count: activities.count { |a| a.type.include?('updated') } },
        { id: 'validations', label: 'Validations', count: activities.count { |a| a.type.include?('validation') } },
        { id: 'shares', label: 'Shares', count: activities.count { |a| a.type.include?('shared') } },
        { id: 'versions', label: 'Versions', count: activities.count { |a| a.type.include?('version') } }
      ]
    end

    class ActivityItem
      attr_reader :type, :action, :user, :timestamp, :details, :icon, :color

      def initialize(type:, action:, user:, timestamp:, details: {}, icon: 'information-circle', color: 'gray')
        @type = type
        @action = action
        @user = user
        @timestamp = timestamp
        @details = details
        @icon = icon
        @color = color
      end

      def description
        case type
        when 'document_created'
          "created this document"
        when 'document_updated'
          if details[:changes]&.any?
            changed_fields = details[:changes].map { |c| c[:field] }.join(', ')
            "updated #{changed_fields}"
          else
            "updated the document"
          end
        when 'validation_requested'
          "requested #{details[:validation_type]} validation"
        when 'validation_approved', 'validation_validated'
          "approved the document"
        when 'validation_rejected'
          "rejected the document"
        when 'document_shared'
          "shared with #{details[:shared_with]}"
        when 'version_created'
          "created version #{details[:version_number]}"
        else
          action
        end
      end

      def user_name
        user&.full_name || 'System'
      end

      def time_ago
        return '' unless timestamp
        
        diff = Time.current - timestamp
        
        case diff
        when 0..59
          'just now'
        when 60..3599
          "#{(diff / 60).round} minutes ago"
        when 3600..86399
          "#{(diff / 3600).round} hours ago"
        when 86400..604799
          "#{(diff / 86400).round} days ago"
        else
          timestamp.to_fs(:short)
        end
      end

      def color_classes
        {
          'green' => 'text-green-600 bg-green-100',
          'blue' => 'text-blue-600 bg-blue-100',
          'red' => 'text-red-600 bg-red-100',
          'yellow' => 'text-yellow-600 bg-yellow-100',
          'purple' => 'text-purple-600 bg-purple-100',
          'gray' => 'text-gray-600 bg-gray-100'
        }[color] || 'text-gray-600 bg-gray-100'
      end
    end
  end
end