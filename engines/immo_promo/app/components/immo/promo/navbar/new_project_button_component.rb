class Immo::Promo::Navbar::NewProjectButtonComponent < ApplicationComponent
  def initialize(current_user:)
    @current_user = current_user
  end

  private

  attr_reader :current_user

  def can_create_project?
    policy(Immo::Promo::Project).create?
  end

  def policy(record)
    Pundit.policy(current_user, record)
  end
end