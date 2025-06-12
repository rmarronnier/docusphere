module HomeHelper
  def greeting_message_for_time
    current_hour = Time.current.hour
    
    case current_hour
    when 0..11
      "Bonne matinée ! Voici votre tableau de bord pour aujourd'hui."
    when 12..17
      "Bon après-midi ! Voici l'état de vos documents et activités."
    else
      "Bonsoir ! Retrouvez vos documents et tâches en cours."
    end
  end
  
  def widget_icon(widget_type)
    case widget_type
    when :pending_documents
      "clipboard-list"
    when :recent_activity
      "clock"
    when :quick_actions
      "lightning-bolt"
    when :statistics
      "chart-bar"
    when :validation_queue
      "check-circle"
    when :project_documents
      "folder-open"
    when :client_documents
      "users"
    else
      "cube"
    end
  end
  
  def widget_color_class(widget_type)
    case widget_type
    when :pending_documents
      "text-orange-600 bg-orange-100"
    when :recent_activity
      "text-blue-600 bg-blue-100"
    when :quick_actions
      "text-purple-600 bg-purple-100"
    when :statistics
      "text-green-600 bg-green-100"
    when :validation_queue
      "text-red-600 bg-red-100"
    when :project_documents
      "text-indigo-600 bg-indigo-100"
    when :client_documents
      "text-yellow-600 bg-yellow-100"
    else
      "text-gray-600 bg-gray-100"
    end
  end
end
