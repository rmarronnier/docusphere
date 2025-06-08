FactoryBot.define do
  factory :immo_promo_time_log, class: 'Immo::Promo::TimeLog' do
    association :task, factory: :immo_promo_task
    association :user
    logged_date { Date.current }
    hours { 4.5 }
    description { 'Travail effectué sur la tâche' }
  end
end