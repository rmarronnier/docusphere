FactoryBot.define do
  factory :user_notification_preference do
    association :user
    notification_type { 'document_shared' }
    delivery_method { 'in_app' }
    frequency { 'immediate' }
    enabled { true }

    trait :disabled do
      enabled { false }
      delivery_method { 'disabled' }
    end

    trait :email_only do
      delivery_method { 'email' }
    end

    trait :both_delivery do
      delivery_method { 'both' }
    end

    trait :daily_digest do
      frequency { 'daily_digest' }
    end

    trait :weekly_digest do
      frequency { 'weekly_digest' }
    end

    trait :urgent_notification do
      notification_type { 'budget_exceeded' }
      delivery_method { 'both' }
      frequency { 'immediate' }
    end

    trait :project_notification do
      notification_type { 'project_created' }
    end

    trait :system_notification do
      notification_type { 'system_announcement' }
      delivery_method { 'both' }
    end
  end
end