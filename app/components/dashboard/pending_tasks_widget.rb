class Dashboard::PendingTasksWidget < ApplicationComponent
  attr_reader :widget_data, :user
  
  def initialize(widget_data:, user:)
    @widget_data = widget_data
    @user = user
  end
  
  private
  
  def tasks
    @tasks ||= widget_data[:data][:tasks] || []
  end
  
  def task_limit
    widget_data.dig(:config, :limit) || 5
  end
  
  def total_count
    widget_data.dig(:data, :total_count) || tasks.size
  end
  
  def loading?
    widget_data[:loading] == true
  end
  
  def has_more_tasks?
    total_count > task_limit
  end
  
  def urgency_class(urgency)
    case urgency
    when 'high'
      'text-red-600 bg-red-100'
    when 'medium'
      'text-yellow-600 bg-yellow-100'
    when 'low'
      'text-green-600 bg-green-100'
    else
      'text-gray-600 bg-gray-100'
    end
  end
  
  def task_icon_class(type)
    case type
    when 'validation'
      'check-circle'
    when 'review'
      'document-text'
    when 'approval'
      'badge-check'
    when 'task'
      'clipboard-list'
    else
      'folder'
    end
  end
  
  def formatted_due_date(date)
    return '' unless date
    
    # Convert to Date if it's a different type
    target_date = case date
                  when String
                    Date.parse(date)
                  when Time, DateTime
                    date.to_date
                  else
                    date
                  end
    
    days_from_now = (target_date - Date.current).to_i
    
    if days_from_now < 0
      "En retard de #{-days_from_now} jour#{'s' if -days_from_now > 1}"
    elsif days_from_now == 0
      "Aujourd'hui"
    elsif days_from_now == 1
      "Demain"
    elsif days_from_now <= 7
      "Dans #{days_from_now} jour#{'s' if days_from_now > 1}"
    else
      target_date.strftime('%d/%m/%Y')
    end
  end
  
  def overdue?(date)
    return false unless date
    
    # Convert to Date if it's a different type
    target_date = case date
                  when String
                    Date.parse(date)
                  when Time, DateTime
                    date.to_date
                  else
                    date
                  end
    
    target_date < Date.current
  end
  
  def all_tasks_path
    helpers.all_tasks_path
  end
end