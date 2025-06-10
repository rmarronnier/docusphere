class DashboardPersonalizationService
  attr_reader :user, :profile
  
  def initialize(user)
    @user = user
    @profile = user.active_profile
  end
  
  def dashboard_data
    personalized_dashboard
  end
  
  def personalized_dashboard
    {
      widgets: active_widgets,
      actions: priority_actions,
      navigation: navigation_items,
      notifications: recent_notifications,
      metrics: key_metrics
    }
  end
  
  def active_widgets
    return [] unless profile
    
    profile.dashboard_widgets.visible.includes(:user_profile).map do |widget|
      {
        id: widget.id,
        type: widget.widget_type,
        position: widget.position,
        size: { width: widget.width, height: widget.height },
        config: widget.config,
        data: load_widget_data(widget)
      }
    end
  end
  
  def priority_actions
    case profile&.profile_type
    when 'direction'
      direction_priority_actions
    when 'chef_projet'
      chef_projet_priority_actions
    when 'juriste'
      juriste_priority_actions
    else
      default_priority_actions
    end
  end
  
  def widget_data_for(widget)
    case widget.widget_type
    when 'quick_access'
      build_quick_access_widget(widget)
    when 'pending_tasks'
      build_pending_tasks_widget(widget)
    when 'notifications'
      build_notifications_widget(widget)
    when 'recent_documents'
      build_recent_documents_widget(widget)
    when 'statistics'
      build_statistics_widget(widget)
    when 'calendar'
      build_calendar_widget(widget)
    when 'team_activity'
      build_team_activity_widget(widget)
    else
      build_default_widget(widget)
    end
  end
  
  private
  
  def load_widget_data(widget)
    widget_data_for(widget)
  end
  
  def direction_priority_actions
    actions = []
    
    # Documents en attente de validation (via document_validations)
    pending_validations = DocumentValidation.where(validator: user, status: 'pending').count
    if pending_validations > 0
      actions << {
        type: 'validation',
        title: 'Validations en attente',
        count: pending_validations,
        urgency: 'high',
        link: '/validations/pending',
        icon: 'check-circle'
      }
    end
    
    # For now, skip Immo::Promo specific actions until the engine is fully integrated
    
    actions
  end
  
  def chef_projet_priority_actions
    actions = []
    
    # Documents à valider
    pending_reviews = DocumentValidation.where(validator: user, status: 'pending').count
    if pending_reviews > 0
      actions << {
        type: 'document',
        title: 'Documents à réviser',
        count: pending_reviews,
        urgency: 'medium',
        link: '/documents/pending_review',
        icon: 'document-text'
      }
    end
    
    # For now, skip Immo::Promo specific actions
    
    actions
  end
  
  def juriste_priority_actions
    actions = []
    
    # For now, return empty array until Immo::Promo is integrated
    # Legal-specific actions will be added later
    
    actions
  end
  
  def default_priority_actions
    # Actions de base pour tous les profils
    actions = []
    
    unread_count = user.notifications.unread.count
    if unread_count > 0
      actions << {
        type: 'notification',
        title: 'Notifications non lues',
        count: unread_count,
        urgency: 'low',
        link: '/notifications',
        icon: 'bell'
      }
    end
    
    actions
  end
  
  def navigation_items
    NavigationService.new(user).navigation_items
  end
  
  def recent_notifications
    user.notifications.unread.order(created_at: :desc).limit(5).map do |notification|
      {
        id: notification.id,
        type: notification.notification_type,
        title: notification.title,
        message: notification.message,
        created_at: notification.created_at,
        urgency: notification.data['urgency'] || 'normal'
      }
    end
  end
  
  def key_metrics
    MetricsService.new(user).key_metrics
  end
  
  def build_quick_access_widget(widget)
    links = NavigationService.new(user).quick_links
    
    {
      id: widget.id,
      type: 'quick_access',
      title: widget.config['title'] || 'Accès rapide',
      config: widget.config,
      data: {
        links: links
      }
    }
  end
  
  def build_pending_tasks_widget(widget)
    limit = widget.config['limit'] || 5
    tasks = []
    
    # Collect validation tasks
    validation_requests = ValidationRequest.where(validatable_type: 'Document', status: 'pending')
                                          .joins(:document_validations)
                                          .where(document_validations: { validator_id: user.id, status: 'pending' })
                                          .order(due_date: :asc)
                                          .limit(limit)
    
    validation_requests.each do |request|
      tasks << {
        id: request.id,
        title: "Valider: #{request.validatable.title}",
        type: 'validation',
        urgency: urgency_for_date(request.due_date),
        due_date: request.due_date,
        assignee: user.full_name,
        link: "/validations/#{request.id}"
      }
    end
    
    # Add more task types here as needed
    # For now, we'll just return validation tasks
    
    {
      id: widget.id,
      type: 'pending_tasks',
      title: widget.config['title'] || 'Tâches en attente',
      config: widget.config,
      data: {
        tasks: tasks.first(limit),
        total_count: tasks.size
      }
    }
  end
  
  def urgency_for_date(due_date)
    return 'high' unless due_date
    
    days_until = (due_date.to_date - Date.current).to_i
    
    if days_until < 0 || days_until <= 1
      'high'
    elsif days_until <= 3
      'medium'
    else
      'low'
    end
  end
  
  def build_notifications_widget(widget)
    limit = widget.config['limit'] || 5
    
    notifications = user.notifications
                        .order(created_at: :desc)
                        .limit(limit + 1)
                        .includes(:notifiable)
    
    formatted_notifications = notifications.first(limit).map do |notification|
      {
        id: notification.id,
        type: notification.notification_type || 'notification',
        title: notification.title,
        message: notification.message,
        created_at: notification.created_at,
        urgency: notification.data['urgency'] || 'normal',
        read: notification.read_at.present?
      }
    end
    
    {
      id: widget.id,
      type: 'notifications',
      title: widget.config['title'] || 'Notifications',
      config: widget.config,
      data: {
        notifications: formatted_notifications,
        total_count: notifications.count,
        unread_count: user.notifications.unread.count
      }
    }
  end
  
  def build_recent_documents_widget(widget)
    organization = user.organization
    limit = widget.config['limit'] || 5
    
    documents = Document.joins(:space)
                       .where(spaces: { organization_id: organization.id })
                       .order(created_at: :desc)
                       .limit(limit + 1)
                       .includes(:uploaded_by, :space, :tags)
    
    {
      id: widget.id,
      type: 'recent_documents',
      title: 'Documents récents',
      config: widget.config,
      data: {
        documents: documents.first(limit),
        total_count: documents.count
      }
    }
  end
  
  def build_statistics_widget(widget)
    metrics = MetricsService.new(user).key_metrics
    
    # Transform metrics to widget format
    stats = metrics.map.with_index do |metric, index|
      {
        id: index + 1,
        label: metric[:label],
        value: metric[:value],
        trend: metric[:trend],
        icon: metric[:icon] || 'chart',
        color: metric[:color] || 'blue'
      }
    end
    
    {
      id: widget.id,
      type: 'statistics',
      title: widget.config['title'] || 'Statistiques',
      config: widget.config,
      data: {
        stats: stats
      }
    }
  end
  
  def build_calendar_widget(widget)
    {
      id: widget.id,
      type: 'calendar',
      title: 'Calendrier',
      content: {
        events: []  # To be implemented
      }
    }
  end
  
  def build_team_activity_widget(widget)
    {
      id: widget.id,
      type: 'team_activity',
      title: 'Activité de l\'équipe',
      content: {
        activities: []  # To be implemented
      }
    }
  end
  
  def build_default_widget(widget)
    {
      id: widget.id,
      type: widget.widget_type,
      title: widget.widget_type.humanize,
      content: {}
    }
  end
end