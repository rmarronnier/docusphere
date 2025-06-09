FactoryBot.define do
  factory :notification do
    association :user
    notification_type { 'document_shared' }
    title { 'Test Notification' }
    message { 'This is a test notification message' }
    read_at { nil }
    data { {} }

    trait :read do
      read_at { 1.hour.ago }
    end

    trait :unread do
      read_at { nil }
    end

    trait :urgent do
      notification_type { 'budget_exceeded' }
      title { 'Budget Exceeded' }
      message { 'The project budget has been exceeded' }
    end

    trait :document_related do
      notification_type { 'document_shared' }
      title { 'Document Shared' }
      message { 'A document has been shared with you' }
      association :notifiable, factory: :document
    end

    trait :project_related do
      notification_type { 'project_created' }
      title { 'New Project Created' }
      message { 'A new project has been created' }
    end

    trait :validation_request do
      notification_type { 'document_validation_requested' }
      title { 'Validation Requested' }
      message { 'Your validation is requested for a document' }
    end

    trait :system_announcement do
      notification_type { 'system_announcement' }
      title { 'System Announcement' }
      message { 'Important system announcement' }
    end

    trait :with_data do
      data { { document_id: 1, user_id: 2, action: 'shared' } }
    end

    # ImmoPromo specific notifications
    trait :project_task_assigned do
      notification_type { 'project_task_assigned' }
      title { 'Task Assigned' }
      message { 'A new task has been assigned to you' }
    end

    trait :stakeholder_assigned do
      notification_type { 'stakeholder_assigned' }
      title { 'Stakeholder Assigned' }
      message { 'You have been assigned to a project' }
    end

    trait :permit_submitted do
      notification_type { 'permit_submitted' }
      title { 'Permit Submitted' }
      message { 'A permit has been submitted' }
    end

    trait :budget_alert do
      notification_type { 'budget_alert' }
      title { 'Budget Alert' }
      message { 'Budget threshold has been reached' }
    end

    trait :risk_identified do
      notification_type { 'risk_identified' }
      title { 'Risk Identified' }
      message { 'A new risk has been identified' }
    end

    trait :maintenance_scheduled do
      notification_type { 'maintenance_scheduled' }
      title { 'Maintenance Scheduled' }
      message { 'System maintenance is scheduled' }
    end

    # Time-based traits
    trait :today do
      created_at { Time.current.beginning_of_day + rand(12).hours }
    end

    trait :yesterday do
      created_at { 1.day.ago }
    end

    trait :this_week do
      created_at { rand(7).days.ago }
    end

    trait :last_week do
      created_at { 1.week.ago - rand(7).days }
    end

    trait :old do
      created_at { 1.month.ago }
    end
  end
  
  factory :search_query do
    user
    name { "recherche test" }
    query_params { {} }
    usage_count { 0 }
    is_favorite { false }
  end
end