class MetricsService
  include MetricsService::ActivityMetrics
  include MetricsService::UserMetrics
  include MetricsService::BusinessMetrics
  include MetricsService::CoreCalculations
  include MetricsService::WidgetData

  def initialize(user)
    @user = user
    @organization = user.organization
  end
end