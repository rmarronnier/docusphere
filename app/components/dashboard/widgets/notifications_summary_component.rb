class Dashboard::Widgets::NotificationsSummaryComponent < ViewComponent::Base
  def initialize(summary:)
    @summary = summary || {}
  end

  private

  attr_reader :summary

  def total_unread
    summary[:total_unread] || 0
  end

  def by_type
    summary[:by_type] || {}
  end

  def by_priority
    summary[:by_priority] || {}
  end

  def recent_notifications
    summary[:recent] || []
  end

  def has_notifications?
    total_unread > 0
  end

  def notification_type_label(type)
    case type
    when 'document_processing_completed'
      'Traitement terminé'
    when 'document_shared'
      'Document partagé'
    when 'validation_request'
      'Validation requise'
    when 'system_announcement'
      'Annonce système'
    else
      type&.humanize || 'Notification'
    end
  end

  def priority_label(priority)
    case priority
    when 'urgent'
      'Urgent'
    when 'high'
      'Élevée'
    when 'normal'
      'Normale'
    when 'low'
      'Faible'
    else
      priority&.humanize || 'Normale'
    end
  end

  def priority_color_class(priority)
    case priority
    when 'urgent'
      'text-red-600 bg-red-100'
    when 'high'
      'text-orange-600 bg-orange-100'
    when 'normal'
      'text-blue-600 bg-blue-100'
    when 'low'
      'text-gray-600 bg-gray-100'
    else
      'text-blue-600 bg-blue-100'
    end
  end

  def format_timestamp(timestamp)
    return "à l'instant" unless timestamp

    diff = Time.current - timestamp

    case diff
    when 0..3599
      minutes = (diff / 60).to_i
      "il y a #{minutes} min"
    when 3600..86399
      hours = (diff / 3600).to_i
      "il y a #{hours}h"
    when 86400..172799
      "hier"
    else
      timestamp.strftime("%d/%m")
    end
  end
end