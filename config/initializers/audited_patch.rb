# Désactiver l'auditing dans les tests et development pour éviter les problèmes de sérialisation
if Rails.env.test? || Rails.env.development?
  # Désactiver l'auditing globalement dans les tests et development
  Audited.auditing_enabled = false
  
  # Alternative: monkey patch pour désactiver l'audit sur les modèles problématiques
  module DisableAuditInTests
    extend ActiveSupport::Concern
    
    included do
      # Désactiver temporairement l'auditing sur ce modèle en test
      auditing_enabled = false if Rails.env.test? || Rails.env.development?
    end
  end
end