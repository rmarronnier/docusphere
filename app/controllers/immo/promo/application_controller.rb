class Immo::Promo::ApplicationController < ApplicationController
  before_action :ensure_immo_promo_access
  layout 'immo_promo'
  
  private
  
  def ensure_immo_promo_access
    unless user_has_immo_promo_access?
      flash[:alert] = "Vous n'avez pas accès au module de promotion immobilière."
      redirect_to root_path
    end
  end
  
  def user_has_immo_promo_access?
    current_user&.admin? || 
    current_user&.super_admin? ||
    current_user&.has_permission?('immo_promo:access')
  end
  
  def skip_authorization?
    false # Always require authorization in Immo::Promo controllers
  end
end