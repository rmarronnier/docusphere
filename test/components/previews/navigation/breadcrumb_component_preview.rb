# @label Breadcrumb Component
class Navigation::BreadcrumbComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Breadcrumb
  def default
    render Navigation::BreadcrumbComponent.new do |breadcrumb|
      breadcrumb.with_item(text: "Accueil", href: "/")
      breadcrumb.with_item(text: "Documents", href: "/documents")
      breadcrumb.with_item(text: "Projet Alpha", href: "/documents/projet-alpha")
      breadcrumb.with_item(text: "Rapport Final", current: true)
    end
  end
  
  # @label Simple Breadcrumb
  def simple
    render Navigation::BreadcrumbComponent.new do |breadcrumb|
      breadcrumb.with_item(text: "Accueil", href: "/")
      breadcrumb.with_item(text: "Profil", current: true)
    end
  end
  
  # @label Deep Navigation
  def deep_navigation
    render Navigation::BreadcrumbComponent.new do |breadcrumb|
      breadcrumb.with_item(text: "Accueil", href: "/")
      breadcrumb.with_item(text: "GED", href: "/ged")
      breadcrumb.with_item(text: "Espace Client", href: "/ged/spaces/client")
      breadcrumb.with_item(text: "Dossier Projet", href: "/ged/spaces/client/folders/projet")
      breadcrumb.with_item(text: "Documents Techniques", href: "/ged/spaces/client/folders/projet/tech")
      breadcrumb.with_item(text: "Plans Architecture", href: "/ged/spaces/client/folders/projet/tech/plans")
      breadcrumb.with_item(text: "Plan Principal", current: true)
    end
  end
  
  # @label With Icons
  def with_icons
    render Navigation::BreadcrumbComponent.new(show_icons: true) do |breadcrumb|
      breadcrumb.with_item(text: "Tableau de bord", href: "/", icon: "home")
      breadcrumb.with_item(text: "Projets", href: "/projects", icon: "folder")
      breadcrumb.with_item(text: "Immo Promo", href: "/projects/immo", icon: "building")
      breadcrumb.with_item(text: "Résidence Les Jardins", current: true, icon: "document")
    end
  end
  
  # @label Compact Style
  def compact
    render Navigation::BreadcrumbComponent.new(compact: true) do |breadcrumb|
      breadcrumb.with_item(text: "Accueil", href: "/")
      breadcrumb.with_item(text: "Administration", href: "/admin")
      breadcrumb.with_item(text: "Utilisateurs", href: "/admin/users")
      breadcrumb.with_item(text: "Jean Dupont", current: true)
    end
  end
  
  # @label Different Separators
  def different_separators
    content_tag :div, class: "space-y-4" do
      [
        content_tag(:div) do
          [
            content_tag(:h3, "Séparateur par défaut (>)", class: "mb-2 font-semibold"),
            render(Navigation::BreadcrumbComponent.new(separator: ">")) do |breadcrumb|
              breadcrumb.with_item(text: "Niveau 1", href: "#")
              breadcrumb.with_item(text: "Niveau 2", href: "#")
              breadcrumb.with_item(text: "Niveau 3", current: true)
            end
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:h3, "Séparateur slash (/)", class: "mb-2 font-semibold"),
            render(Navigation::BreadcrumbComponent.new(separator: "/")) do |breadcrumb|
              breadcrumb.with_item(text: "Niveau 1", href: "#")
              breadcrumb.with_item(text: "Niveau 2", href: "#")
              breadcrumb.with_item(text: "Niveau 3", current: true)
            end
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:h3, "Séparateur flèche (→)", class: "mb-2 font-semibold"),
            render(Navigation::BreadcrumbComponent.new(separator: "→")) do |breadcrumb|
              breadcrumb.with_item(text: "Niveau 1", href: "#")
              breadcrumb.with_item(text: "Niveau 2", href: "#")
              breadcrumb.with_item(text: "Niveau 3", current: true)
            end
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
end