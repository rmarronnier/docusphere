FactoryBot.define do
  factory :immo_promo_task, class: 'Immo::Promo::Task' do
    sequence(:name) { |n| "Tâche #{n}" }
    description { 'Description de la tâche' }
    task_type { 'technical' }
    status { 'pending' }
    priority { 'medium' }
    start_date { Date.current }
    end_date { Date.current + 1.week }
    association :phase, factory: :immo_promo_phase
    association :assigned_to, factory: :user
    estimated_hours { 8 }

    trait :urgent do
      priority { 'critical' }
      end_date { Date.current + 1.day }
    end

    trait :in_progress do
      status { 'in_progress' }
      progress_percentage { 50 }
    end

    trait :completed do
      status { 'completed' }
      completed_date { Date.current }
      progress_percentage { 100 }
    end

    trait :overdue do
      status { 'in_progress' }
      end_date { Date.current - 2.days }
    end
  end
end
