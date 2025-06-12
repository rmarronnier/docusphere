class Dashboard::RecentActivityWidgetComponent < ViewComponent::Base
  def initialize(activities:, user:)
    @activities = activities || []
    @user = user
  end
  
  private
  
  def any_activities?
    @activities.any?
  end
  
  def activity_icon(activity)
    if activity.respond_to?(:views) && activity.views.where(user: @user).any?
      'eye'
    elsif activity.uploaded_by == @user && activity.created_at > 7.days.ago
      'upload'
    elsif activity.shares.where(shared_by: @user).any?
      'share'
    elsif activity.updated_at > activity.created_at
      'pencil'
    else
      'document'
    end
  end
  
  def activity_description(activity)
    if activity.respond_to?(:views) && activity.views.where(user: @user).any?
      last_view = activity.views.where(user: @user).order(created_at: :desc).first
      "Vous avez consulté ce document #{time_ago_description(last_view.created_at)}"
    elsif activity.uploaded_by == @user && activity.created_at > 7.days.ago
      "Vous avez ajouté ce document #{time_ago_description(activity.created_at)}"
    elsif activity.shares.where(shared_by: @user).any?
      last_share = activity.shares.where(shared_by: @user).order(created_at: :desc).first
      "Vous avez partagé ce document #{time_ago_description(last_share.created_at)}"
    elsif activity.updated_at > activity.created_at
      "Document modifié #{time_ago_description(activity.updated_at)}"
    else
      "Activité sur ce document #{time_ago_description(activity.updated_at)}"
    end
  end
  
  def activity_color_class(activity_icon)
    case activity_icon
    when 'eye'
      'text-blue-600 bg-blue-100'
    when 'upload'
      'text-green-600 bg-green-100'
    when 'share'
      'text-purple-600 bg-purple-100'
    when 'pencil'
      'text-yellow-600 bg-yellow-100'
    else
      'text-gray-600 bg-gray-100'
    end
  end
  
  def time_ago_description(time)
    return "à l'instant" unless time
    
    diff = Time.current - time
    
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
      time.strftime("le %d/%m/%Y")
    end
  end
  
  def document_type_label(document)
    return "Document" unless document.file.attached?
    
    content_type = document.file.content_type
    
    case content_type
    when /pdf/
      "PDF"
    when /word|docx/
      "Word"
    when /excel|xlsx/
      "Excel"
    when /powerpoint|pptx/
      "PowerPoint"
    when /image/
      "Image"
    when /video/
      "Vidéo"
    when /audio/
      "Audio"
    else
      "Document"
    end
  end
  
  def format_file_size(size)
    return "0 B" unless size
    
    case size
    when 0..1.kilobyte
      "#{size} B"
    when 1.kilobyte..1.megabyte
      "#{(size.to_f / 1.kilobyte).round(1)} KB"
    when 1.megabyte..1.gigabyte
      "#{(size.to_f / 1.megabyte).round(1)} MB"
    else
      "#{(size.to_f / 1.gigabyte).round(2)} GB"
    end
  end
end