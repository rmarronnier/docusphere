class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # Protect from forgery attacks
  protect_from_forgery with: :exception
  
  # Configure Devise parameters
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  
  # Pundit authorization - only check if action exists
  after_action :verify_authorized, except: :index, unless: :skip_pundit?, if: :pundit_action_exists?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?, if: :pundit_action_exists?
  
  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :organization_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :organization_id])
  end
  
  def skip_pundit?
    devise_controller? || 
    params[:controller] == 'home' || 
    params[:controller] == 'ged' ||
    params[:controller] == 'rails/health'
  end
  
  def pundit_action_exists?
    self.class.action_methods.include?(action_name)
  end
  
  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
    redirect_to(request.referrer || root_path)
  end
end
