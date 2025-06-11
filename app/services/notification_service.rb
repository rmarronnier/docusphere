class NotificationService
  include NotificationService::ValidationNotifications
  include NotificationService::ProjectNotifications
  include NotificationService::StakeholderNotifications
  include NotificationService::PermitNotifications
  include NotificationService::BudgetNotifications
  include NotificationService::RiskNotifications
  include NotificationService::UserUtilities
  include NotificationService::DocumentNotifications

  class << self
    private
    
    def authorizable_title(authorizable)
      if authorizable.respond_to?(:title)
        authorizable.title
      elsif authorizable.respond_to?(:name)
        authorizable.name
      else
        "##{authorizable.id}"
      end
    end
    
    def validatable_title(validatable)
      if validatable.respond_to?(:validatable_title)
        validatable.validatable_title
      elsif validatable.respond_to?(:title)
        validatable.title
      elsif validatable.respond_to?(:name)
        validatable.name
      else
        "#{validatable.class.name} ##{validatable.id}"
      end
    end
  end
end