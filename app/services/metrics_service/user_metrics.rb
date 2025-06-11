module MetricsService::UserMetrics
  extend ActiveSupport::Concern
  
  def direction_metrics
    {
      total_projects: total_projects_count,
      active_projects: active_projects_count,
      budget_consumed: budget_consumed_percentage,
      team_performance: calculate_team_performance,
      risk_level: calculate_risk_level
    }
  end

  def chef_projet_metrics
    {
      projects_managed: total_projects_count,
      completion_rate: calculate_completion_rate,
      budget_utilization: calculate_budget_utilization,
      team_members: team_members_count,
      progress: project_progress_percentage,
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
      documents: user_documents_count,
      notifications: unread_notifications_count,
      recent_activity: recent_activity_count,
      storage_used: storage_usage_mb,
      tasks: assigned_tasks_count,
      last_week_activity: last_week_activity
    }
  end
end