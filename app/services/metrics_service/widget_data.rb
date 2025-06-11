module MetricsService::WidgetData
  extend ActiveSupport::Concern
  
  def statistics_widget_data
    profile_type = @user.active_profile&.profile_type
    
    case profile_type
    when 'direction'
      {
        total_projects: total_projects_count,
        active_projects: active_projects_count,
        budget_consumed: budget_consumed_percentage,
        efficiency_score: calculate_efficiency_score
      }
    when 'chef_projet'
      {
        projects_count: total_projects_count,
        completion_rate: calculate_completion_rate,
        team_performance: calculate_team_performance,
        milestones_status: milestone_completion_status
      }
    else
      default_widget_data
    end
  end

  def activity_widget_data
    {
      recent_activities: recent_activities,
      weekly_progress: last_week_activity,
      timeline: activity_timeline
    }
  end

  def performance_widget_data
    profile_type = @user.active_profile&.profile_type
    
    case profile_type
    when 'direction', 'chef_projet'
      {
        efficiency: calculate_efficiency_score,
        quality: calculate_quality_score,
        timeliness: calculate_timeliness_score,
        radar_data: performance_radar_data
      }
    when 'commercial'
      {
        sales_performance: sales_conversion_rate,
        customer_satisfaction: customer_satisfaction_score,
        pipeline_health: sales_pipeline_value
      }
    else
      {
        tasks_completed: completed_tasks_count,
        documents_processed: user_documents_count,
        activity_level: recent_activity_count
      }
    end
  end

  def default_widget_data
    {
      documents: user_documents_count,
      tasks: assigned_tasks_count,
      notifications: unread_notifications_count
    }
  end

  def widget_metrics(widget_type)
    case widget_type.to_s
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
end