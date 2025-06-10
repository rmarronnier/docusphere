FactoryBot.define do
  factory :user_profile do
    user
    profile_type { 'assistant_rh' }
    active { true }
    
    trait :direction do
      profile_type { 'direction' }
    end
    
    trait :chef_projet do
      profile_type { 'chef_projet' }
    end
    
    trait :juriste do
      profile_type { 'juriste' }
    end
    
    trait :architecte do
      profile_type { 'architecte' }
    end
    
    trait :commercial do
      profile_type { 'commercial' }
    end
    
    trait :controleur do
      profile_type { 'controleur' }
    end
    
    trait :expert_technique do
      profile_type { 'expert_technique' }
    end
    
    trait :assistant_rh do
      profile_type { 'assistant_rh' }
    end
    
    trait :communication do
      profile_type { 'communication' }
    end
    
    trait :admin_system do
      profile_type { 'admin_system' }
    end
    
    trait :inactive do
      active { false }
    end
    
    trait :with_preferences do
      preferences do
        {
          theme: 'light',
          language: 'fr',
          timezone: 'Europe/Paris',
          date_format: 'DD/MM/YYYY'
        }
      end
    end
    
    trait :with_dashboard_config do
      dashboard_config do
        {
          layout: 'grid',
          refresh_interval: 300,
          collapsed_sections: []
        }
      end
    end
    
    trait :with_notification_settings do
      notification_settings do
        {
          email_alerts: true,
          push_notifications: false,
          alert_types: ['urgent', 'validation']
        }
      end
    end
  end
end