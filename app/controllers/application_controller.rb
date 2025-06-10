class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # Protect from forgery attacks
  protect_from_forgery with: :exception
  
  # Include component helpers
  helper ComponentsHelper
  
  # Configure Devise parameters
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :set_current_user
  
  # Pundit authorization
  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?
  
  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def set_current_user
    Current.user = current_user
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :organization_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :organization_id])
  end
  
  def skip_pundit?
    devise_controller? || 
    params[:controller] == 'home' ||
    params[:controller] == 'dashboard' ||
    params[:controller] == 'rails/health'
  end
  
  def user_not_authorized
    if request.format.json?
      render json: { error: "Vous n'êtes pas autorisé à effectuer cette action." }, status: :forbidden
    else
      flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
      redirect_to(request.referrer || root_path)
    end
  end
  
  def authenticate_user!
    if request.format.json? && !user_signed_in?
      render json: { error: 'Authentication required' }, status: :unauthorized
    else
      super
    end
  end
end
