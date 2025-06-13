class Immo::Promo::ProjectCard::InfoComponent < ApplicationComponent
  def initialize(project:, show_financial: true, variant: :default)
    @project = project
    @show_financial = show_financial
    @variant = variant
  end

  private

  attr_reader :project, :show_financial, :variant

  def formatted_surface_area
    return nil unless project.total_surface_area
    number_with_delimiter(project.total_surface_area.to_i)
  end

  def show_financial_info?
    show_financial && can_view_financial_data?
  end

  def can_view_financial_data?
    return true unless respond_to?(:helpers)
    return true unless helpers.respond_to?(:policy)
    
    policy = helpers.policy(project)
    policy.respond_to?(:view_financial_data?) ? policy.view_financial_data? : false
  rescue
    false
  end

  def formatted_total_budget
    return nil unless project.total_budget
    project.total_budget.format(symbol: true, thousands_separator: ' ', no_cents: true)
  end

  def formatted_current_budget
    return nil unless project.current_budget
    project.current_budget.format(symbol: true, thousands_separator: ' ', no_cents: true)
  end

  def budget_usage_percentage
    project.budget_usage_percentage if project.respond_to?(:budget_usage_percentage)
  end

  def is_over_budget?
    project.respond_to?(:is_over_budget?) && project.is_over_budget?
  end

  def compact_layout?
    variant == :compact
  end
end