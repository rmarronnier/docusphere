FactoryBot.define do
  factory :notification do
    user
    notification_type { "info" }
    title { "Nouvelle notification" }
    message { "Message de notification" }
    is_read { false }
    data { {} }
    
    trait :read do
      is_read { true }
    end
    
    trait :document_related do
      notification_type { "document_shared" }
      association :notifiable, factory: :document
    end
  end
  
  factory :search_query do
    user
    query { "recherche test" }
    search_type { "documents" }
    filters { {} }
    results_count { 10 }
  end
end