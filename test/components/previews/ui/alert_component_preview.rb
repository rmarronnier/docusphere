# @label Alert Component
class Ui::AlertComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Alert
  def default
    render Ui::AlertComponent.new(message: "Ceci est une alerte d'information par défaut.")
  end
  
  # @label Alert Types
  def types
    content_tag :div, class: "space-y-4" do
      safe_join([
        render(Ui::AlertComponent.new(
          type: :info,
          message: "Information : Votre session expire dans 15 minutes."
        )),
        
        render(Ui::AlertComponent.new(
          type: :success,
          message: "Succès : Le document a été enregistré avec succès."
        )),
        
        render(Ui::AlertComponent.new(
          type: :warning,
          message: "Attention : Cette action est irréversible."
        )),
        
        render(Ui::AlertComponent.new(
          type: :error,
          message: "Erreur : Impossible de charger le fichier. Veuillez réessayer."
        ))
      ])
    end
  end
  
  # @label With Title
  def with_title
    content_tag :div, class: "space-y-4" do
      safe_join([
        render(Ui::AlertComponent.new(
          type: :info,
          title: "Nouvelle fonctionnalité",
          message: "Découvrez notre nouveau système de validation des documents."
        )),
        
        render(Ui::AlertComponent.new(
          type: :warning,
          title: "Maintenance prévue",
          message: "Le système sera indisponible le 15 juin de 2h à 4h du matin."
        ))
      ])
    end
  end
  
  # @label Dismissible Alerts
  def dismissible
    content_tag :div, class: "space-y-4" do
      safe_join([
        render(Ui::AlertComponent.new(
          type: :info,
          message: "Cette alerte peut être fermée.",
          dismissible: true
        )),
        
        render(Ui::AlertComponent.new(
          type: :success,
          title: "Upload réussi",
          message: "5 documents ont été importés avec succès.",
          dismissible: true
        ))
      ])
    end
  end
  
  # @label With Actions
  def with_actions
    render Ui::AlertComponent.new(
      type: :warning,
      title: "Action requise",
      message: "3 documents sont en attente de votre validation."
    ) do
      content_tag :div, class: "mt-4" do
        safe_join([
          link_to("Voir les documents", "#", class: "btn btn-sm btn-warning mr-2"),
          link_to("Plus tard", "#", class: "text-sm text-yellow-700 hover:text-yellow-800")
        ])
      end
    end
  end
  
  # @label Complex Alert
  def complex_example
    render Ui::AlertComponent.new(
      type: :error,
      title: "Erreurs de validation",
      dismissible: true
    ) do
      content_tag :div do
        safe_join([
          content_tag(:p, "Les erreurs suivantes ont été détectées :", class: "mb-2"),
          content_tag(:ul, class: "list-disc list-inside space-y-1") do
            safe_join([
              content_tag(:li, "Le titre du document est obligatoire"),
              content_tag(:li, "La date ne peut pas être dans le futur"),
              content_tag(:li, "Au moins un tag doit être sélectionné")
            ])
          end,
          content_tag(:div, class: "mt-4") do
            link_to("Corriger les erreurs", "#", class: "btn btn-sm btn-danger")
          end
        ])
      end
    end
  end
  
  # @label Auto-dismiss
  # @display theme dark
  def auto_dismiss
    # Note: In real usage, this would auto-dismiss after 5 seconds
    render Ui::AlertComponent.new(
      type: :success,
      message: "Sauvegarde automatique effectuée (disparaît après 5 secondes)",
      dismissible: true,
      data: { auto_dismiss: 5000 }
    )
  end
end