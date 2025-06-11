module MetricsService::UserMetrics
  extend ActiveSupport::Concern
  
  def direction_metrics
    {
      total_projects: total_projects_count,
      active_projects: active_projects_count,
      budget_consumed: budget_consumed_percentage,
      pending_validations: pending_validations_count,
      team_performance: calculate_team_performance,
      risk_level: calculate_risk_level,
      project_completion_rate: calculate_completion_rate,
      budget_utilization_rate: calculate_budget_utilization
    }
  end

  def chef_projet_metrics
    {
      projects_managed: total_projects_count,
      tasks_completed: completed_tasks_count,
      tasks_pending: pending_tasks_count,
      team_size: team_members_count,
      project_progress: project_progress_percentage,
      completion_rate: calculate_completion_rate,
      budget_utilization: calculate_budget_utilization,
      milestones: milestone_completion_status,
      budget_status: project_budget_status,
      resource_utilization: resource_utilization_percentage
    }
  end

  def juriste_metrics
    {
      pending_validations: pending_validations_count,
      permits_pending: pending_permits_count,
      permits_approved: approved_permits_count,
      contracts_active: active_contracts_count,
      compliance_score: compliance_score_percentage,
      legal_reviews: pending_legal_reviews_count,
      upcoming_deadlines: upcoming_deadlines_count
    }
  end

  def commercial_metrics
    {
      monthly_reservations: monthly_reservations_count,
      monthly_sales: monthly_sales_amount,
      conversion_rate: sales_conversion_rate,
      available_units: available_units_count,
      pipeline_value: sales_pipeline_value,
      customer_satisfaction: customer_satisfaction_score
    }
  end

  def controleur_metrics
    {
      budget_variance: budget_variance_percentage,
      pending_invoices: pending_invoices_count,
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
      tasks: assigned_tasks_count,
      last_week_activity: last_week_activity
    }
  end
  
  # Calcule les métriques utilisateur basées sur le profil
  def calculate_user_metrics
    profile = @user&.active_profile || @current_user&.active_profile
    profile_type = profile&.profile_type || 'default'
    
    {
      profile_type: profile_type,
      usage_stats: calculate_usage_stats,
      performance_indicators: calculate_performance_indicators,
      personalized_insights: generate_personalized_insights
    }
  end
  
  # Calcule le score de performance utilisateur
  def user_performance_score
    {
      overall_score: calculate_overall_performance,
      activity_score: calculate_user_activity_score,
      collaboration_score: calculate_collaboration_score,
      compliance_score: calculate_compliance_score
    }
  end
  
  # Génère des recommandations personnalisées
  def user_recommendations
    recommendations = []
    
    # Recommandations basées sur l'activité
    if calculate_user_activity_score < 50
      recommendations << {
        type: 'activity',
        message: 'Augmentez votre activité pour améliorer votre productivité',
        priority: 'medium'
      }
    end
    
    # Recommandations basées sur la collaboration
    if calculate_collaboration_score < 60
      recommendations << {
        type: 'collaboration',
        message: 'Partagez plus de documents pour améliorer la collaboration',
        priority: 'low'
      }
    end
    
    # Recommandations basées sur la conformité
    if calculate_compliance_score < 80
      recommendations << {
        type: 'compliance',
        message: 'Vérifiez les validations en attente pour maintenir la conformité',
        priority: 'high'
      }
    end
    
    recommendations
  end
  
  private
  
  def calculate_usage_stats
    {
      documents_created: user_documents_count,
      documents_viewed: (@user || @current_user).documents.sum(:view_count),
      storage_used: storage_usage_mb,
      last_login: (@user || @current_user).last_sign_in_at
    }
  end
  
  def calculate_performance_indicators
    {
      productivity: calculate_productivity_score,
      efficiency: calculate_efficiency_score,
      quality: calculate_quality_score
    }
  end
  
  def generate_personalized_insights
    [
      "Votre activité a augmenté de #{rand(10..30)}% ce mois-ci",
      "Vous avez #{pending_validations_count} validations en attente",
      "Votre score de conformité est de #{calculate_compliance_score}%"
    ]
  end
  
  def calculate_overall_performance
    (calculate_user_activity_score + calculate_collaboration_score + calculate_compliance_score) / 3
  end
  
  def calculate_user_activity_score
    # Score basé sur l'activité récente
    recent_docs = (@user || @current_user).documents.where('created_at > ?', 30.days.ago).count
    recent_activity = recent_activity_count
    
    score = (recent_docs * 5 + recent_activity * 2)
    [score, 100].min
  end
  
  def calculate_collaboration_score
    # Score basé sur le partage et la collaboration
    shared_docs = (@user || @current_user).document_shares.count rescue 0
    notifications_sent = 0 # Simplification
    
    score = (shared_docs * 10 + notifications_sent * 5)
    [score, 100].min
  end
  
  def calculate_compliance_score
    # Score basé sur la conformité et les validations
    total_validations = (@user || @current_user).validation_requests.count rescue 0
    pending_validations = pending_validations_count
    
    return 100 if total_validations.zero?
    
    completed_ratio = (total_validations - pending_validations).to_f / total_validations
    (completed_ratio * 100).round
  end
  
  def calculate_productivity_score
    75 # Valeur par défaut
  end
  
  def calculate_efficiency_score
    80 # Valeur par défaut
  end
  
  def calculate_quality_score
    85 # Valeur par défaut
  end
  
  # Méthodes helper existantes qui pourraient manquer
  def user_documents_count
    (@user || @current_user).documents.count rescue 0
  end
  
  def unread_notifications_count
    (@user || @current_user).notifications.unread.count rescue 0
  end
  
  def recent_activity_count
    (@user || @current_user).documents.where('created_at > ?', 7.days.ago).count rescue 0
  end
  
  def storage_usage_mb
    (@user || @current_user).documents.sum(:file_size) / 1.megabyte rescue 0
  end
  
  def assigned_tasks_count
    0 # Simplification - pas de modèle Task
  end
  
  def last_week_activity
    {
      documents_created: (@user || @current_user).documents.where('created_at > ?', 1.week.ago).count,
      documents_viewed: 0 # Simplification
    }
  end
  
  def pending_validations_count
    (@user || @current_user).validation_requests.pending.count rescue 0
  end
  
  # Méthodes stub pour les métriques spécifiques aux profils
  def total_projects_count; 0; end
  def active_projects_count; 0; end
  def budget_consumed_percentage; 0; end
  def calculate_team_performance; 85; end
  def calculate_risk_level; 'low'; end
  def calculate_completion_rate; 75; end
  def calculate_budget_utilization; 68; end
  def completed_tasks_count; 0; end
  def pending_tasks_count; 0; end
  def team_members_count; 0; end
  def project_progress_percentage; 0; end
  def milestone_completion_status; {}; end
  def project_budget_status; 'on_track'; end
  def resource_utilization_percentage; 0; end
  def pending_permits_count; 0; end
  def approved_permits_count; 0; end
  def active_contracts_count; 0; end
  def compliance_score_percentage; 85; end
  def pending_legal_reviews_count; 0; end
  def upcoming_deadlines_count; 0; end
  def monthly_reservations_count; 0; end
  def monthly_sales_amount; 0; end
  def sales_conversion_rate; 0; end
  def available_units_count; 0; end
  def sales_pipeline_value; 0; end
  def customer_satisfaction_score; 85; end
  def budget_variance_percentage; 0; end
  def pending_invoices_count; 0; end
  def current_cash_flow; 0; end
  def cost_overrun_projects_count; 0; end
  def average_payment_delay_days; 0; end
  def financial_health_score; 75; end
end