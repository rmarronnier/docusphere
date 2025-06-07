class ApplicationController < ActionController::Base
  # Protect from forgery attacks
  protect_from_forgery with: :exception
  
  # Configure Devise parameters
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  private
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :organization_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :organization_id])
  end
end
