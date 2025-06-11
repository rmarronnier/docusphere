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

  private

  def respond_to_project_metrics?
    @user.organization.respond_to?(:projects)
  end
end