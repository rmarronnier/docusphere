module ImmoPromo
  module ApplicationHelper
    # Helper methods for the ImmoPromo engine
    
    # Include specific helper modules
    include Immo::Promo::StakeholdersHelper if defined?(Immo::Promo::StakeholdersHelper)
    include Immo::Promo::PermitsHelper if defined?(Immo::Promo::PermitsHelper)
  end
end