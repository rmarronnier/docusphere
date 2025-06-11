module MetricsService::ActivityMetrics
  extend ActiveSupport::Concern
  
  def key_metrics
    profile_type = @user.active_profile&.profile_type
    
    case profile_type
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
    start_date = days.days.ago
    
    {
      period: "#{days} derniers jours",
      documents: {
        created: user_documents_created_since(start_date),
        modified: user_documents_modified_since(start_date),
        shared: user_documents_shared_since(start_date)
      },
      tasks: {
        completed: tasks_completed_since(start_date),
        assigned: tasks_assigned_since(start_date)
      },
      notifications: {
        received: notifications_received_since(start_date),
        read: notifications_read_since(start_date)
      },
      activity_score: calculate_activity_score(start_date)
    }
  end

  def performance_indicators
    {
      efficiency: calculate_efficiency_score,
      productivity: calculate_productivity_score,
      quality: calculate_quality_score
    }
  end

  def trending_metrics
    current_week = activity_summary(7)
    previous_week = activity_summary(14) # Les 14 derniers jours pour avoir la semaine précédente
    
    {
      documents: calculate_trend('documents', 
        current_week[:documents][:created], 
        previous_week[:documents][:created] - current_week[:documents][:created]
      ),
      tasks: calculate_trend('tasks',
        current_week[:tasks][:completed],
        previous_week[:tasks][:completed] - current_week[:tasks][:completed]
      ),
      activity: calculate_trend('activity',
        current_week[:activity_score],
        previous_week[:activity_score] - current_week[:activity_score]
      )
    }
  end

  def comparison_data(period = :week)
    case period
    when :week
      current_data = activity_summary(7)
      previous_data = activity_summary(14)
      # Extraire seulement la semaine précédente
      previous_week_data = {
        documents: { created: previous_data[:documents][:created] - current_data[:documents][:created] },
        tasks: { completed: previous_data[:tasks][:completed] - current_data[:tasks][:completed] },
        activity_score: previous_data[:activity_score] - current_data[:activity_score]
      }
    when :month
      current_data = activity_summary(30)
      previous_data = activity_summary(60)
      previous_week_data = {
        documents: { created: previous_data[:documents][:created] - current_data[:documents][:created] },
        tasks: { completed: previous_data[:tasks][:completed] - current_data[:tasks][:completed] },
        activity_score: previous_data[:activity_score] - current_data[:activity_score]
      }
    else
      current_data = activity_summary(7)
      previous_week_data = { documents: { created: 0 }, tasks: { completed: 0 }, activity_score: 0 }
    end
    
    {
      current: current_data,
      previous: previous_week_data,
      comparisons: {
        documents: compare_metric('Documents créés', 
          current_data[:documents][:created], 
          previous_week_data[:documents][:created]
        ),
        tasks: compare_metric('Tâches complétées',
          current_data[:tasks][:completed],
          previous_week_data[:tasks][:completed]
        ),
        activity: compare_metric('Score d\'activité',
          current_data[:activity_score],
          previous_week_data[:activity_score]
        )
      }
    }
  end

  def recent_activities
    activities = []
    
    # Documents récents
    recent_docs = @user.documents.limit(5).order(created_at: :desc) rescue []
    recent_docs.each do |doc|
      activities << {
        type: 'document',
        action: 'created',
        title: doc.title,
        timestamp: doc.created_at
      }
    end
    
    # Notifications récentes
    recent_notifications = @user.notifications.limit(3).order(created_at: :desc) rescue []
    recent_notifications.each do |notif|
      activities << {
        type: 'notification',
        action: 'received',
        title: notif.title,
        timestamp: notif.created_at
      }
    end
    
    activities.sort_by { |a| a[:timestamp] }.reverse.first(10)
  end

  def activity_timeline
    timeline = []
    
    (0..6).each do |days_ago|
      date = days_ago.days.ago.to_date
      daily_activity = calculate_daily_activity(date)
      
      timeline << {
        date: date,
        score: daily_activity,
        events: daily_activity > 5 ? 'high' : daily_activity > 2 ? 'medium' : 'low'
      }
    end
    
    timeline.reverse
  end

  def performance_radar_data
    {
      productivity: calculate_productivity_score,
      quality: calculate_quality_score,
      timeliness: calculate_timeliness_score,
      collaboration: calculate_collaboration_score,
      innovation: calculate_innovation_score
    }
  end

  private

  def user_documents_created_since(date)
    @user.documents.where('created_at >= ?', date).count rescue 0
  end

  def user_documents_modified_since(date)
    @user.documents.where('updated_at >= ?', date).count rescue 0
  end

  def user_documents_shared_since(date)
    # Approximation - documents partagés par l'utilisateur
    @user.documents.joins(:document_shares).where('document_shares.created_at >= ?', date).count rescue 0
  end

  def tasks_completed_since(date)
    if @user.respond_to?(:assigned_tasks)
      @user.assigned_tasks.where('completed_at >= ?', date).count
    else
      0
    end
  end

  def tasks_assigned_since(date)
    if @user.respond_to?(:assigned_tasks)
      @user.assigned_tasks.where('created_at >= ?', date).count
    else
      0
    end
  end

  def notifications_received_since(date)
    @user.notifications.where('created_at >= ?', date).count rescue 0
  end

  def notifications_read_since(date)
    @user.notifications.where('read_at >= ?', date).count rescue 0
  end

  def calculate_activity_score(start_date)
    docs_score = user_documents_created_since(start_date) * 2
    tasks_score = tasks_completed_since(start_date) * 3
    notifications_score = notifications_read_since(start_date) * 1
    
    [docs_score + tasks_score + notifications_score, 100].min
  end

  def calculate_productivity_score
    recent_docs = user_documents_created_since(7.days.ago)
    recent_tasks = tasks_completed_since(7.days.ago)
    
    base_score = (recent_docs * 5 + recent_tasks * 8)
    [base_score, 100].min
  end

  def calculate_collaboration_score
    shared_docs = user_documents_shared_since(30.days.ago)
    notifications_read = notifications_read_since(30.days.ago)
    
    collaboration_base = (shared_docs * 3 + notifications_read * 1)
    [collaboration_base, 100].min
  end

  def calculate_innovation_score
    # Score basé sur la variété des activités et l'utilisation de nouvelles fonctionnalités
    base_score = 60
    variety_bonus = recent_activities.map { |a| a[:type] }.uniq.count * 10
    
    [base_score + variety_bonus, 100].min
  end

  def calculate_daily_activity(date)
    docs = @user.documents.where(created_at: date.beginning_of_day..date.end_of_day).count rescue 0
    tasks = tasks_completed_since(date.beginning_of_day) - tasks_completed_since(date.end_of_day) rescue 0
    
    docs + tasks
  end
end