# @label Notification Component
class Ui::NotificationComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Notification
  def default
    render Ui::NotificationComponent.new(
      type: "info",
      title: "Information",
      message: "Ceci est une notification d'information."
    )
  end
  
  # @label All Notification Types
  def all_types
    content_tag :div, class: "space-y-4" do
      [
        render(Ui::NotificationComponent.new(
          type: "success",
          title: "Succès",
          message: "L'opération s'est déroulée avec succès."
        )),
        render(Ui::NotificationComponent.new(
          type: "info",
          title: "Information",
          message: "Voici une information importante à retenir."
        )),
        render(Ui::NotificationComponent.new(
          type: "warning",
          title: "Attention",
          message: "Cette action nécessite votre attention particulière."
        )),
        render(Ui::NotificationComponent.new(
          type: "error",
          title: "Erreur",
          message: "Une erreur s'est produite lors du traitement de votre demande."
        ))
      ].join.html_safe
    end
  end
  
  # @label With Actions
  def with_actions
    content_tag :div, class: "space-y-4" do
      [
        render(Ui::NotificationComponent.new(
          type: "info",
          title: "Nouvelle mise à jour disponible",
          message: "Une nouvelle version de l'application est disponible.",
          dismissible: true
        )) do |notification|
          notification.with_action(text: "Mettre à jour", href: "#", variant: "primary")
          notification.with_action(text: "Plus tard", href: "#", variant: "secondary")
        end,
        render(Ui::NotificationComponent.new(
          type: "warning",
          title: "Espace de stockage faible",
          message: "Il ne vous reste que 10% d'espace de stockage disponible.",
          dismissible: true
        )) do |notification|
          notification.with_action(text: "Gérer l'espace", href: "#", variant: "warning")
        end
      ].join.html_safe
    end
  end
  
  # @label Dismissible Notifications
  def dismissible
    content_tag :div, class: "space-y-4" do
      [
        render(Ui::NotificationComponent.new(
          type: "success",
          title: "Document enregistré",
          message: "Votre document a été enregistré avec succès.",
          dismissible: true
        )),
        render(Ui::NotificationComponent.new(
          type: "info",
          title: "Synchronisation",
          message: "Vos données sont en cours de synchronisation.",
          dismissible: false
        ))
      ].join.html_safe
    end
  end
  
  # @label Compact Notifications
  def compact
    content_tag :div, class: "space-y-2" do
      [
        render(Ui::NotificationComponent.new(
          type: "success",
          message: "Fichier téléchargé avec succès.",
          compact: true,
          dismissible: true
        )),
        render(Ui::NotificationComponent.new(
          type: "error",
          message: "Impossible de se connecter au serveur.",
          compact: true,
          dismissible: true
        )),
        render(Ui::NotificationComponent.new(
          type: "warning",
          message: "Session sur le point d'expirer.",
          compact: true,
          dismissible: false
        ))
      ].join.html_safe
    end
  end
end