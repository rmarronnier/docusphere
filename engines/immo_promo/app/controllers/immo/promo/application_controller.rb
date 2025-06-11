module Immo
  module Promo
    class ApplicationController < ::ImmoPromo::ApplicationController
      before_action :ensure_immo_promo_access
      layout 'immo_promo'

      private

      def ensure_immo_promo_access
        # Use Pundit to check access
        authorize_immo_promo_access!
      rescue Pundit::NotAuthorizedError
        flash[:alert] = "Vous n'avez pas accès au module de promotion immobilière."
        redirect_to root_path
      end

      def authorize_immo_promo_access!
        # Create a dummy policy object to check access
        policy = Immo::Promo::ApplicationPolicy.new(current_user, :immo_promo_access)
        raise Pundit::NotAuthorizedError unless policy.access?
      end

      def user_has_immo_promo_access?
        # Keep this method for compatibility but delegate to Pundit
        policy = Immo::Promo::ApplicationPolicy.new(current_user, :immo_promo_access)
        policy.access?
      end

      def skip_authorization?
        false # Always require authorization in Immo::Promo controllers
      end
    end
  end
end
