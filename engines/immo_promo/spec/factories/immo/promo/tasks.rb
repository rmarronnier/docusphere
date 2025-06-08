FactoryBot.define do
  factory :immo_promo_task, class: 'Immo::Promo::Task' do
    sequence(:name) { |n| "Tâche #{n}" }
    description { 'Description de la tâche' }
    status { 'pending' }
    priority { 'medium' }
    start_date { Date.current }
    due_date { Date.current + 1.week }
    association :phase, factory: :immo_promo_phase
    association :project, factory: :immo_promo_project
    association :assigned_to, factory: :user
    estimated_hours { 8 }
    
    trait :urgent do
      priority { 'urgent' }
      due_date { Date.current + 1.day }
    end
    
    trait :in_progress do
      status { 'in_progress' }
      actual_start_date { Date.current }
      progress_percentage { 50 }
    end
    
    trait :completed do
      status { 'completed' }
      actual_start_date { Date.current - 3.days }
      actual_end_date { Date.current }
      actual_hours { 10 }
      progress_percentage { 100 }
    end
    
    trait :overdue do
      status { 'in_progress' }
      due_date { Date.current - 2.days }
    end
  end
end