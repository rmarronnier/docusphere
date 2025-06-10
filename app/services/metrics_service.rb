class MetricsService
  attr_reader :user, :profile, :organization
  
  def initialize(user)
    @user = user
    @profile = user.active_profile
    @organization = user.organization
  end
  
  def key_metrics
    case profile&.profile_type
    when 'direction'
      direction_metrics
    when 'chef_projet'
      chef_projet_metrics
    when 'juriste'
      juriste_metrics
    when 'commercial'
      commercial_metrics
    when 'controleur'
      controleur_metrics
    else
      default_metrics
    end
  end
  
  def activity_summary(days = 30)
    end_date = Date.today
    start_date = end_date - days.days
    
    # Initialize array with all dates
    summary = (start_date..end_date).map do |date|
      {
        date: date,
        count: 0,
        type: 'documents'
      }
    end
    
    # Get document activity
    documents = Document.joins(:space).where(
      spaces: { organization_id: organization.id },
      created_at: start_date.beginning_of_day..end_date.end_of_day
    ).group_by { |d| d.created_at.to_date }
    
    # Update counts
    summary.each do |day|
      if documents[day[:date]]
        day[:count] = documents[day[:date]].count
      end
    end
    
    summary
  end
  
  def performance_indicators
    {
      efficiency_score: calculate_efficiency_score,
      quality_score: calculate_quality_score,
      timeliness_score: calculate_timeliness_score
    }
  end
  
  def trending_metrics
    current_period = 1.week.ago..Time.current
    previous_period = 2.weeks.ago..1.week.ago
    
    [
      calculate_trend('Documents', 
        Document.joins(:space).where(spaces: { organization_id: organization.id }, created_at: current_period).count,
        Document.joins(:space).where(spaces: { organization_id: organization.id }, created_at: previous_period).count
      ),
      calculate_trend('Notifications',
        user.notifications.where(created_at: current_period).count,
        user.notifications.where(created_at: previous_period).count
      ),
      calculate_trend('Validations',
        DocumentValidation.where(validator: user, created_at: current_period).count,
        DocumentValidation.where(validator: user, created_at: previous_period).count
      )
    ]
  end
  
  def widget_metrics(widget_type)
    case widget_type
    when 'statistics'
      statistics_widget_data
    when 'activity'
      activity_widget_data
    when 'performance'
      performance_widget_data
    else
      default_widget_data
    end
  end
  
  def comparison_data(period = :week)
    case period
    when :week
      current = 1.week.ago..Time.current
      previous = 2.weeks.ago..1.week.ago
    when :month
      current = 1.month.ago..Time.current
      previous = 2.months.ago..1.month.ago
    else
      current = 1.day.ago..Time.current
      previous = 2.days.ago..1.day.ago
    end
    
    {
      current_period: current,
      previous_period: previous,
      metrics: [
        compare_metric('Documents uploadés', 
          Document.where(uploaded_by: user, created_at: current).count,
          Document.where(uploaded_by: user, created_at: previous).count
        ),
        compare_metric('Notifications reçues',
          user.notifications.where(created_at: current).count,
          user.notifications.where(created_at: previous).count
        )
      ]
    }
  end
  
  private
  
  def direction_metrics
    {
      total_projects: total_projects_count,
      active_projects: active_projects_count,
      budget_consumed: budget_consumed_percentage,
      pending_validations: pending_validations_count,
      project_completion_rate: calculate_completion_rate,
      budget_utilization_rate: calculate_budget_utilization,
      team_performance: calculate_team_performance,
      risk_level: calculate_risk_level
    }
  end
  
  def chef_projet_metrics
    {
      tasks_completed: completed_tasks_count,
      tasks_pending: pending_tasks_count,
      team_size: team_members_count,
      project_progress: project_progress_percentage,
      milestone_status: milestone_completion_status,
      budget_status: project_budget_status,
      resource_utilization: resource_utilization_percentage
    }
  end
  
  def juriste_metrics
    {
      permits_pending: pending_permits_count,
      permits_approved: approved_permits_count,
      contracts_active: active_contracts_count,
      compliance_score: compliance_score_percentage,
      legal_reviews_pending: pending_legal_reviews_count,
      deadline_alerts: upcoming_deadlines_count
    }
  end
  
  def commercial_metrics
    {
      reservations_month: monthly_reservations_count,
      sales_amount: monthly_sales_amount,
      conversion_rate: sales_conversion_rate,
      available_units: available_units_count,
      pipeline_value: sales_pipeline_value,
      customer_satisfaction: customer_satisfaction_score
    }
  end
  
  def controleur_metrics
    {
      budget_variance: budget_variance_percentage,
      invoices_pending: pending_invoices_count,
      cash_flow: current_cash_flow,
      cost_overruns: cost_overrun_projects_count,
      payment_delays: average_payment_delay_days,
      financial_health: financial_health_score
    }
  end
  
  def default_metrics
    {
      documents_uploaded: user_documents_count,
      unread_notifications: unread_notifications_count,
      recent_activity: recent_activity_count,
      storage_used: storage_usage_mb,
      tasks_assigned: assigned_tasks_count
    }
  end
  
  def statistics_widget_data
    {
      title: 'Statistiques',
      metrics: [
        { label: 'Documents', value: user_documents_count, icon: 'document' },
        { label: 'Notifications', value: unread_notifications_count, icon: 'bell' },
        { label: 'Tâches', value: assigned_tasks_count, icon: 'check' }
      ],
      chart_data: {
        labels: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
        datasets: [{
          label: 'Activité',
          data: last_week_activity
        }]
      }
    }
  end
  
  def activity_widget_data
    {
      title: 'Activité récente',
      metrics: recent_activities,
      chart_data: {
        type: 'line',
        data: activity_timeline
      }
    }
  end
  
  def performance_widget_data
    {
      title: 'Performance',
      metrics: performance_indicators.map do |key, value|
        {
          label: key.to_s.humanize,
          value: value,
          suffix: '%'
        }
      end,
      chart_data: {
        type: 'radar',
        data: performance_radar_data
      }
    }
  end
  
  def default_widget_data
    {
      title: 'Métriques',
      metrics: [],
      chart_data: {}
    }
  end
  
  def calculate_trend(name, current_value, previous_value)
    change = if previous_value.zero?
      current_value > 0 ? 100.0 : 0.0
    else
      ((current_value - previous_value).to_f / previous_value * 100).round(1)
    end
    
    {
      name: name,
      value: current_value,
      trend: change > 0 ? 'up' : (change < 0 ? 'down' : 'stable'),
      change: change.abs,
      period: '7 jours'
    }
  end
  
  def compare_metric(name, current, previous)
    change_percentage = if previous.zero?
      current > 0 ? 100.0 : 0.0
    else
      ((current - previous).to_f / previous * 100).round(1)
    end
    
    {
      name: name,
      current: current,
      previous: previous,
      change_percentage: change_percentage
    }
  end
  
  def calculate_efficiency_score
    # Simplified calculation based on document processing time
    # In reality, this would involve more complex metrics
    base_score = 75
    documents_processed = Document.where(uploaded_by: user).count
    
    score = base_score + (documents_processed * 0.1)
    [score, 100].min.round
  end
  
  def calculate_quality_score
    # Based on validation success rate
    validations = DocumentValidation.where(validator: user)
    return 80 if validations.empty?
    
    approved = validations.where(status: 'approved').count
    total = validations.count
    
    (approved.to_f / total * 100).round
  end
  
  def calculate_timeliness_score
    # Based on average processing time
    # Simplified for now
    85
  end
  
  # Metric calculations (simplified implementations)
  def total_projects_count
    # In real implementation, would query Immo::Promo::Project
    10
  end
  
  def active_projects_count
    5
  end
  
  def budget_consumed_percentage
    67.5
  end
  
  def pending_validations_count
    DocumentValidation.where(validator: user, status: 'pending').count
  end
  
  def calculate_completion_rate
    75.0
  end
  
  def calculate_budget_utilization
    82.3
  end
  
  def calculate_team_performance
    88
  end
  
  def calculate_risk_level
    'medium'
  end
  
  def completed_tasks_count
    15
  end
  
  def pending_tasks_count
    8
  end
  
  def team_members_count
    12
  end
  
  def project_progress_percentage
    64.0
  end
  
  def milestone_completion_status
    'on_track'
  end
  
  def project_budget_status
    'within_budget'
  end
  
  def resource_utilization_percentage
    78.5
  end
  
  def pending_permits_count
    3
  end
  
  def approved_permits_count
    12
  end
  
  def active_contracts_count
    8
  end
  
  def compliance_score_percentage
    92.0
  end
  
  def pending_legal_reviews_count
    2
  end
  
  def upcoming_deadlines_count
    5
  end
  
  def monthly_reservations_count
    18
  end
  
  def monthly_sales_amount
    2_450_000
  end
  
  def sales_conversion_rate
    23.5
  end
  
  def available_units_count
    42
  end
  
  def sales_pipeline_value
    8_750_000
  end
  
  def customer_satisfaction_score
    4.2
  end
  
  def budget_variance_percentage
    -3.2
  end
  
  def pending_invoices_count
    28
  end
  
  def current_cash_flow
    1_250_000
  end
  
  def cost_overrun_projects_count
    2
  end
  
  def average_payment_delay_days
    12
  end
  
  def financial_health_score
    'good'
  end
  
  def user_documents_count
    @user_documents_count ||= Document.where(uploaded_by: user).count
  end
  
  def unread_notifications_count
    @unread_notifications_count ||= user.notifications.unread.count
  end
  
  def recent_activity_count
    Document.where(uploaded_by: user).where('created_at > ?', 1.week.ago).count
  end
  
  def storage_usage_mb
    # Simplified - would calculate actual storage
    234
  end
  
  def assigned_tasks_count
    # Would query tasks when available
    5
  end
  
  def last_week_activity
    # Returns array of daily activity counts
    [12, 15, 8, 22, 18, 5, 3]
  end
  
  def recent_activities
    # Returns recent activity items
    []
  end
  
  def activity_timeline
    # Returns timeline data
    {}
  end
  
  def performance_radar_data
    # Returns radar chart data
    {}
  end
end