# frozen_string_literal: true

class Documents::KeyboardShortcutsModalComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize
    super
  end

  private

  def shortcuts
    [
      {
        section: "Navigation",
        items: [
          { key: "←", description: "Document précédent" },
          { key: "→", description: "Document suivant" },
          { key: "↑", description: "Page précédente (PDF)" },
          { key: "↓", description: "Page suivante (PDF)" }
        ]
      },
      {
        section: "Actions",
        items: [
          { key: "D", description: "Télécharger le document" },
          { key: "P", description: "Imprimer le document" },
          { key: "S", description: "Partager le document" },
          { key: "E", description: "Éditer les métadonnées" }
        ]
      },
      {
        section: "Affichage",
        items: [
          { key: "F", description: "Mode plein écran" },
          { key: "+", description: "Zoomer" },
          { key: "-", description: "Dézoomer" },
          { key: "0", description: "Réinitialiser le zoom" }
        ]
      },
      {
        section: "Système",
        items: [
          { key: "?", description: "Afficher cette aide" },
          { key: "ESC", description: "Fermer les modales/plein écran" }
        ]
      }
    ]
  end
end