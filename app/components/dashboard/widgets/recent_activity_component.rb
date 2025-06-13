class Dashboard::Widgets::RecentActivityComponent < ViewComponent::Base
  def initialize(activities:)
    @activities = activities || []
  end

  private

  attr_reader :activities

  def any_activities?
    activities.any?
  end

  def activity_icon(activity)
    case activity[:type]
    when 'document_uploaded'
      'upload'
    when 'notification'
      'bell'
    when 'document_viewed'
      'eye'
    when 'document_shared'
      'share'
    else
      'activity'
    end
  end

  def activity_color_class(icon)
    case icon
    when 'upload'
      'text-green-600 bg-green-100'
    when 'bell'
      'text-blue-600 bg-blue-100'
    when 'eye'
      'text-purple-600 bg-purple-100'
    when 'share'
      'text-yellow-600 bg-yellow-100'
    else
      'text-gray-600 bg-gray-100'
    end
  end

  def format_timestamp(timestamp)
    return "à l'instant" unless timestamp

    diff = Time.current - timestamp

    case diff
    when 0..59
      "il y a #{diff.to_i} secondes"
    when 60..3599
      minutes = (diff / 60).to_i
      "il y a #{minutes} minute#{minutes > 1 ? 's' : ''}"
    when 3600..86399
      hours = (diff / 3600).to_i
      "il y a #{hours} heure#{hours > 1 ? 's' : ''}"
    when 86400..172799
      "hier"
    when 172800..604799
      days = (diff / 86400).to_i
      "il y a #{days} jours"
    else
      timestamp.strftime("le %d/%m/%Y")
    end
  end
end