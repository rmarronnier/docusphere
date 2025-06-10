# @label Search Form Component
class Forms::SearchFormComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Search Form
  def default
    render Forms::SearchFormComponent.new(
      placeholder: "Rechercher des documents...",
      action: "/search"
    )
  end
  
  # @label Search with Filters
  def with_filters
    render Forms::SearchFormComponent.new(
      placeholder: "Rechercher...",
      action: "/search",
      show_filters: true
    ) do |form|
      form.with_filter(
        name: "category",
        label: "Catégorie",
        type: "select",
        options: [["Tous", ""], ["Documents", "documents"], ["Images", "images"], ["Vidéos", "videos"]]
      )
      form.with_filter(
        name: "date_range",
        label: "Période",
        type: "select",
        options: [["Toutes", ""], ["Cette semaine", "week"], ["Ce mois", "month"], ["Cette année", "year"]]
      )
    end
  end
  
  # @label Compact Search
  def compact
    render Forms::SearchFormComponent.new(
      placeholder: "Recherche rapide...",
      action: "/search",
      compact: true,
      show_button: false
    )
  end
  
  # @label Search with Suggestions
  def with_suggestions
    render Forms::SearchFormComponent.new(
      placeholder: "Tapez pour voir les suggestions...",
      action: "/search",
      autocomplete: true,
      suggestions_url: "/search/suggestions"
    )
  end
  
  # @label Advanced Search Form
  def advanced
    render Forms::SearchFormComponent.new(
      placeholder: "Recherche avancée...",
      action: "/search/advanced",
      advanced: true
    ) do |form|
      form.with_advanced_field(
        name: "title",
        label: "Titre du document",
        type: "text",
        placeholder: "Rechercher dans le titre"
      )
      form.with_advanced_field(
        name: "content",
        label: "Contenu",
        type: "text",
        placeholder: "Rechercher dans le contenu"
      )
      form.with_advanced_field(
        name: "author",
        label: "Auteur",
        type: "text",
        placeholder: "Nom de l'auteur"
      )
      form.with_advanced_field(
        name: "tags",
        label: "Tags",
        type: "text",
        placeholder: "Tags séparés par des virgules"
      )
      form.with_advanced_field(
        name: "date_from",
        label: "Date de début",
        type: "date"
      )
      form.with_advanced_field(
        name: "date_to",
        label: "Date de fin",
        type: "date"
      )
    end
  end
  
  # @label Different Sizes
  def sizes
    content_tag :div, class: "space-y-6" do
      [
        content_tag(:div) do
          [
            content_tag(:h3, "Small", class: "mb-3 font-semibold"),
            render(Forms::SearchFormComponent.new(
              placeholder: "Recherche small...",
              action: "/search",
              size: "sm"
            ))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:h3, "Medium", class: "mb-3 font-semibold"),
            render(Forms::SearchFormComponent.new(
              placeholder: "Recherche medium...",
              action: "/search",
              size: "md"
            ))
          ].join.html_safe
        end,
        content_tag(:div) do
          [
            content_tag(:h3, "Large", class: "mb-3 font-semibold"),
            render(Forms::SearchFormComponent.new(
              placeholder: "Recherche large...",
              action: "/search",
              size: "lg"
            ))
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
end