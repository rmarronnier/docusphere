module MetricsService::CoreCalculations
  extend ActiveSupport::Concern
  
  def calculate_trend(name, current_value, previous_value)
    return { trend: 'stable', percentage: 0 } if previous_value.nil? || previous_value.zero?
    
    percentage = ((current_value - previous_value).to_f / previous_value * 100).round(2)
    trend = if percentage > 5
              'up'
            elsif percentage < -5
              'down'
            else
              'stable'
            end
    
    { trend: trend, percentage: percentage.abs }
  end

  def compare_metric(name, current, previous)
    {
      name: name,
      current: current,
      previous: previous,
      change: current - previous,
      percentage_change: previous.zero? ? 0 : ((current - previous).to_f / previous * 100).round(2)
    }
  end

  def calculate_efficiency_score
    # Score basé sur plusieurs facteurs
    completion_factor = calculate_completion_rate / 100.0
    budget_factor = [1.0, 2.0 - (budget_consumed_percentage / 100.0)].min
    team_factor = calculate_team_performance / 100.0
    
    ((completion_factor + budget_factor + team_factor) / 3 * 100).round(2)
  end

  def calculate_quality_score
    # Score de qualité basé sur les validations et révisions
    total_validations = pending_validations_count + 10 # Assumé validations complétées
    success_rate = total_validations > 0 ? (10.0 / total_validations * 100) : 100
    
    compliance_factor = compliance_score_percentage / 100.0
    
    ((success_rate + compliance_factor * 100) / 2).round(2)
  end

  def calculate_timeliness_score
    # Score basé sur le respect des délais
    total_deadlines = upcoming_deadlines_count + 5 # Assumé deadlines respectées
    on_time_rate = total_deadlines > 0 ? (5.0 / total_deadlines * 100) : 100
    
    [on_time_rate, 100].min.round(2)
  end

  # Métriques de base
  def total_projects_count
    @user.organization.projects.count rescue 0
  end

  def active_projects_count
    @user.organization.projects.where(status: ['planning', 'in_progress']).count rescue 0
  end

  def budget_consumed_percentage
    return 0 unless respond_to_project_metrics?
    # Simulation - dans un vrai projet, calculer le % réel
    rand(60..85)
  end

  def pending_validations_count
    @user.organization.validation_requests.where(status: 'pending').count rescue 0
  end

  def calculate_completion_rate
    total = total_projects_count
    return 100 if total.zero?
    
    completed = @user.organization.projects.where(status: 'completed').count rescue 0
    (completed.to_f / total * 100).round(2)
  end

  def calculate_budget_utilization
    budget_consumed_percentage
  end

  def calculate_team_performance
    # Score basé sur l'activité de l'équipe
    base_score = 75
    activity_bonus = recent_activity_count > 10 ? 15 : recent_activity_count * 1.5
    
    [base_score + activity_bonus, 100].min.round(2)
  end

  def calculate_risk_level
    # Niveau de risque basé sur plusieurs facteurs
    budget_risk = budget_consumed_percentage > 80 ? 'high' : 'medium'
    timeline_risk = upcoming_deadlines_count > 5 ? 'high' : 'low'
    
    budget_risk == 'high' || timeline_risk == 'high' ? 'high' : 'medium'
  end

  def completed_tasks_count
    # Compter les tâches assignées et complétées
    if @user.respond_to?(:assigned_tasks)
      @user.assigned_tasks.where(status: 'completed').count
    else
      0
    end
  end

  def pending_tasks_count
    if @user.respond_to?(:assigned_tasks)
      @user.assigned_tasks.where(status: ['pending', 'in_progress']).count
    else
      0
    end
  end

  def team_members_count
    @user.organization.users.count rescue 1
  end

  def project_progress_percentage
    # Moyenne des progrès des projets
    projects = @user.organization.projects rescue []
    return 0 if projects.empty?
    
    total_progress = projects.sum { |p| p.try(:progress_percentage) || rand(40..90) }
    (total_progress.to_f / projects.count).round(2)
  end

  def milestone_completion_status
    # Status des jalons
    rand(70..95)
  end

  def project_budget_status
    100 - budget_consumed_percentage
  end

  def resource_utilization_percentage
    team_performance = calculate_team_performance
    activity_factor = [recent_activity_count / 20.0, 1.0].min
    
    (team_performance * activity_factor).round(2)
  end

  # Méthodes additionnelles pour les métriques
  def user_documents_count
    @user.documents.count rescue 0
  end

  def unread_notifications_count
    @user.notifications.where(read_at: nil).count rescue 0
  end

  def recent_activity_count
    # Activities in the last 7 days
    docs = user_documents_created_since(7.days.ago)
    notifications = notifications_received_since(7.days.ago)
    docs + notifications
  end

  def storage_usage_mb
    # Sum file sizes from documents
    total_bytes = @user.documents.joins(:file_attachments).sum('active_storage_blobs.byte_size') rescue 0
    (total_bytes / 1.megabyte.to_f).round(2)
  end

  def assigned_tasks_count
    pending_tasks_count
  end

  def last_week_activity
    activity_summary(7)
  end

  def pending_permits_count
    if @user.organization.respond_to?(:permits)
      @user.organization.permits.where(status: 'pending').count
    else
      0
    end
  end

  def approved_permits_count
    if @user.organization.respond_to?(:permits)
      @user.organization.permits.where(status: 'approved').count
    else
      0
    end
  end

  def active_contracts_count
    if @user.organization.respond_to?(:contracts)
      @user.organization.contracts.where(status: 'active').count
    else
      0
    end
  end

  def compliance_score_percentage
    # Simulation d'un score de conformité
    rand(85..98)
  end

  def pending_legal_reviews_count
    @user.organization.validation_requests.where(status: 'pending', category: 'legal').count rescue 0
  end

  def upcoming_deadlines_count
    # Documents or projects with deadlines in the next 30 days
    @user.organization.documents.where('expires_at BETWEEN ? AND ?', Date.today, 30.days.from_now).count rescue 0
  end

  def monthly_reservations_count
    if @user.organization.respond_to?(:reservations)
      @user.organization.reservations.where(created_at: 1.month.ago..Time.current).count
    else
      0
    end
  end

  def monthly_sales_amount
    if @user.organization.respond_to?(:sales)
      @user.organization.sales.where(created_at: 1.month.ago..Time.current).sum(:amount)
    else
      0
    end
  end

  def sales_conversion_rate
    # Simulation d'un taux de conversion
    rand(15..35)
  end

  def available_units_count
    if @user.organization.respond_to?(:units)
      @user.organization.units.where(status: 'available').count
    else
      0
    end
  end

  def sales_pipeline_value
    # Simulation valeur pipeline
    rand(1_000_000..5_000_000)
  end

  def customer_satisfaction_score
    # Simulation score satisfaction
    rand(80..95)
  end

  def budget_variance_percentage
    # Variance entre budget prévu et réel
    rand(-15..15)
  end

  def pending_invoices_count
    if @user.organization.respond_to?(:invoices)
      @user.organization.invoices.where(status: 'pending').count
    else
      0
    end
  end

  def current_cash_flow
    # Simulation cash flow
    rand(100_000..500_000)
  end

  def cost_overrun_projects_count
    if @user.organization.respond_to?(:projects)
      # Projets avec dépassement de budget
      @user.organization.projects.where('actual_budget > planned_budget').count rescue 0
    else
      0
    end
  end

  def average_payment_delay_days
    # Délai moyen de paiement
    rand(15..45)
  end

  def financial_health_score
    # Score de santé financière
    rand(70..95)
  end

  # Méthode helper pour activity_summary
  def user_documents_created_since(date)
    @user.documents.where('created_at >= ?', date).count rescue 0
  end

  def notifications_received_since(date)
    @user.notifications.where('created_at >= ?', date).count rescue 0
  end

  private

  def respond_to_project_metrics?
    @user.organization.respond_to?(:projects)
  end
end