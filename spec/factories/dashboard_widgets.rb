FactoryBot.define do
  factory :dashboard_widget do
    user_profile
    sequence(:widget_type) { |n| "widget_type_#{n}" }
    sequence(:position) { |n| n - 1 } # Positions start at 0
    width { 1 }
    height { 1 }
    visible { true }
    config { {} }
    
    trait :large do
      width { 2 }
      height { 2 }
    end
    
    trait :wide do
      width { 2 }
      height { 1 }
    end
    
    trait :tall do
      width { 1 }
      height { 2 }
    end
    
    trait :hidden do
      visible { false }
    end
    
    trait :with_config do
      config do
        {
          title: 'Custom Widget',
          refresh_interval: 300,
          show_header: true
        }
      end
    end
    
    # Specific widget types
    trait :portfolio_overview do
      widget_type { 'portfolio_overview' }
      width { 2 }
      height { 1 }
    end
    
    trait :task_kanban do
      widget_type { 'task_kanban' }
      width { 2 }
      height { 2 }
    end
    
    trait :financial_summary do
      widget_type { 'financial_summary' }
      width { 1 }
      height { 1 }
    end
    
    trait :risk_matrix do
      widget_type { 'risk_matrix' }
      width { 1 }
      height { 1 }
    end
  end
end