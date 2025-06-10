class Immo::Promo::NavbarComponent < ApplicationComponent
  def initialize(current_user:, current_project: nil)
    @current_user = current_user
    @current_project = current_project
  end

  private

  attr_reader :current_user, :current_project

  def on_project_view?
    current_project.present?
  end
  
  def on_dashboard?
    !on_project_view?
  end
  
  def can_create_project?
    # Check if user can create projects in any organization
    current_user.organizations.any? do |org|
      Pundit.policy(current_user, Immo::Promo::Project.new(organization: org)).create?
    end
  rescue
    false
  end
  
  def can_edit_project?
    return false unless current_project
    Pundit.policy(current_user, current_project).edit?
  rescue
    false
  end
  
  def can_manage_stakeholders?
    # Check if user can manage stakeholders globally
    current_user.admin? || current_user.permissions["manage_stakeholders"] == true
  rescue
    false
  end
end