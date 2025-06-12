# frozen_string_literal: true

module Navigation
  class NotificationBellComponent < ViewComponent::Base
    include Turbo::StreamsHelper
    include ActionCable::Helpers::ActionCableHelper

    def initialize(user:, max_preview: 5)
      @user = user
      @max_preview = max_preview
      @notifications = load_recent_notifications
      @unread_count = load_unread_count
    end

    private

    attr_reader :user, :max_preview, :notifications, :unread_count

    def load_recent_notifications
      user.notifications
        .includes(:notifiable)
        .order(created_at: :desc)
        .limit(max_preview)
    end

    def load_unread_count
      user.notifications.unread.count
    end

    def notification_icon(notification)
      case notification.notification_type
      when 'validation_request'
        'clipboard-check'
      when 'document_shared'
        'share'
      when 'document_locked'
        'lock-closed'
      when 'document_unlocked'
        'lock-open'
      when 'comment_added'
        'chat-alt'
      when 'task_assigned'
        'briefcase'
      when 'deadline_approaching'
        'clock'
      when 'compliance_alert'
        'exclamation'
      when 'approval_received'
        'check-circle'
      when 'rejection_received'
        'x-circle'
      else
        'bell'
      end
    end

    def notification_color(notification)
      # Utiliser la priorité pour déterminer la couleur
      case notification.priority
      when 'urgent'
        'red'
      when 'high'
        'orange'
      when 'normal'
        'blue'
      when 'low'
        'gray'
      else
        'gray'
      end
    end

    def notification_title(notification)
      case notification.notification_type
      when 'validation_request'
        'Validation requise'
      when 'document_shared'
        'Document partagé'
      when 'document_locked'
        'Document verrouillé'
      when 'document_unlocked'
        'Document déverrouillé'
      when 'comment_added'
        'Nouveau commentaire'
      when 'task_assigned'
        'Tâche assignée'
      when 'deadline_approaching'
        'Échéance proche'
      when 'compliance_alert'
        'Alerte conformité'
      when 'approval_received'
        'Validation acceptée'
      when 'rejection_received'
        'Validation refusée'
      else
        'Nouvelle notification'
      end
    end

    def notification_description(notification)
      # Truncate to 100 characters for preview
      notification.message&.truncate(100) || 'Aucune description disponible'
    end

    def notification_time(notification)
      if notification.created_at > 1.hour.ago
        "il y a #{time_ago_in_words(notification.created_at)}"
      elsif notification.created_at.today?
        notification.created_at.strftime("%H:%M")
      elsif notification.created_at.yesterday?
        "Hier à #{notification.created_at.strftime('%H:%M')}"
      else
        notification.created_at.strftime("%d/%m à %H:%M")
      end
    end

    def notification_path(notification)
      return '#' unless notification.notifiable

      case notification.notifiable_type
      when 'Document'
        helpers.ged_document_path(notification.notifiable)
      when 'ValidationRequest'
        if notification.notifiable.validatable_type == 'Document'
          helpers.ged_document_path(notification.notifiable.validatable)
        else
          '#'
        end
      when 'DocumentShare'
        helpers.ged_document_path(notification.notifiable.document)
      when 'Task', 'Immo::Promo::Task'
        helpers.immo_promo_engine.project_phase_task_path(
          notification.notifiable.phase.project,
          notification.notifiable.phase,
          notification.notifiable
        )
      else
        '#'
      end
    end

    def mark_as_read_path(notification)
      helpers.mark_as_read_notification_path(notification)
    end

    def mark_all_as_read_path
      helpers.mark_all_as_read_notifications_path
    end

    def turbo_stream_channel
      "notifications_#{user.id}"
    end

    def show_badge?
      unread_count > 0
    end

    def badge_text
      unread_count > 99 ? '99+' : unread_count.to_s
    end

    def badge_pulse?
      # Pulse animation for urgent unread notifications
      user.notifications.unread.where(priority: ['urgent', 'high']).exists?
    end

    def empty_state_message
      "Aucune notification récente"
    end

    def empty_state_description
      "Vous recevrez des notifications ici lorsque des actions importantes se produiront."
    end

    # Real-time update helpers
    def notification_container_id
      "notification-bell-#{user.id}"
    end

    def notification_list_id
      "notification-list-#{user.id}"
    end

    def notification_badge_id
      "notification-badge-#{user.id}"
    end

    def notification_item_id(notification)
      "notification-item-#{notification.id}"
    end
  end
end