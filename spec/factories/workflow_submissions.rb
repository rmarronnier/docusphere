FactoryBot.define do
  factory :workflow_submission do
    workflow
    submitted_by { association :user }
    submittable { association :document }
    status { 'pending' }
    priority { 'normal' }
    
    trait :in_progress do
      status { 'in_progress' }
      started_at { Time.current }
    end
    
    trait :waiting_for_approval do
      status { 'waiting_for_approval' }
    end
    
    trait :approved do
      status { 'approved' }
      decision { 'approved' }
      decided_at { Time.current }
      decided_by { association :user }
    end
    
    trait :rejected do
      status { 'rejected' }
      decision { 'rejected' }
      decided_at { Time.current }
      decided_by { association :user }
    end
    
    trait :completed do
      status { 'completed' }
      completed_at { Time.current }
    end
    
    trait :cancelled do
      status { 'cancelled' }
    end
    
    trait :with_due_date do
      due_date { 7.days.from_now }
    end
    
    trait :overdue do
      due_date { 2.days.ago }
      status { 'in_progress' }
    end
  end
end