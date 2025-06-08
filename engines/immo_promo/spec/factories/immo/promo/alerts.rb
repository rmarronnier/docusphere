FactoryBot.define do
  factory :alert do
    association :project, factory: :immo_promo_project
    alert_type { 'risk_escalation' }
    title { 'Escalade de risque' }
    message { 'Un risque a été escaladé au niveau critique' }
    severity { 'high' }
    status { 'active' }
    triggered_at { Time.current }
    
    trait :acknowledged do
      status { 'acknowledged' }
      acknowledged_at { 1.hour.ago }
      association :acknowledged_by, factory: :user
    end
    
    trait :resolved do
      status { 'resolved' }
      resolved_at { 1.day.ago }
      resolution_notes { 'Problème résolu' }
    end
  end
end