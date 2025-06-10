class Dashboard::ActionsPanelComponent < ApplicationComponent
  attr_reader :actions, :user, :collapsed
  
  def initialize(actions:, user:, collapsed: false)
    @actions = actions
    @user = user
    @collapsed = collapsed
  end
  
  private
  
  def grouped_actions
    @grouped_actions ||= actions.group_by { |action| action[:type] }
  end
  
  def urgency_color(urgency)
    case urgency
    when 'critical' then 'red'
    when 'high' then 'orange'
    when 'medium' then 'yellow'
    else 'gray'
    end
  end
  
  def urgency_classes(urgency)
    color = urgency_color(urgency)
    "bg-#{color}-100 text-#{color}-800 border-#{color}-200"
  end
  
  def total_actions_count
    actions.sum { |action| action[:count] || 0 }
  end
  
  def icon_path_for(icon_name)
    case icon_name
    when 'check-circle', 'check'
      'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
    when 'clock'
      'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'
    when 'bell'
      'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9'
    when 'exclamation'
      'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z'
    else
      'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    end
  end
end