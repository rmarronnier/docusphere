# @label Form Field Component
class Forms::FieldComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Text Field
  def default
    render Forms::FieldComponent.new(
      type: "text",
      name: "name",
      label: "Nom complet",
      placeholder: "Entrez votre nom"
    )
  end
  
  # @label Different Field Types
  def field_types
    content_tag :div, class: "space-y-6 max-w-md" do
      [
        render(Forms::FieldComponent.new(
          type: "text",
          name: "text_field",
          label: "Champ texte",
          placeholder: "Texte simple"
        )),
        render(Forms::FieldComponent.new(
          type: "email",
          name: "email_field",
          label: "Email",
          placeholder: "user@example.com"
        )),
        render(Forms::FieldComponent.new(
          type: "password",
          name: "password_field",
          label: "Mot de passe",
          placeholder: "••••••••"
        )),
        render(Forms::FieldComponent.new(
          type: "textarea",
          name: "textarea_field",
          label: "Description",
          placeholder: "Entrez une description détaillée...",
          rows: 4
        )),
        render(Forms::FieldComponent.new(
          type: "select",
          name: "select_field",
          label: "Catégorie",
          options: [["Option 1", "1"], ["Option 2", "2"], ["Option 3", "3"]]
        ))
      ].join.html_safe
    end
  end
  
  # @label Field States
  def field_states
    content_tag :div, class: "space-y-6 max-w-md" do
      [
        render(Forms::FieldComponent.new(
          type: "text",
          name: "normal_field",
          label: "Champ normal",
          value: "Valeur par défaut"
        )),
        render(Forms::FieldComponent.new(
          type: "text",
          name: "required_field",
          label: "Champ requis",
          required: true,
          placeholder: "Ce champ est obligatoire"
        )),
        render(Forms::FieldComponent.new(
          type: "text",
          name: "disabled_field",
          label: "Champ désactivé",
          disabled: true,
          value: "Valeur non modifiable"
        )),
        render(Forms::FieldComponent.new(
          type: "text",
          name: "error_field",
          label: "Champ avec erreur",
          value: "Valeur incorrecte",
          error: "Ce champ contient une erreur"
        ))
      ].join.html_safe
    end
  end
  
  # @label With Icons and Help Text
  def with_icons_and_help
    content_tag :div, class: "space-y-6 max-w-md" do
      [
        render(Forms::FieldComponent.new(
          type: "text",
          name: "search_field",
          label: "Rechercher",
          placeholder: "Tapez votre recherche...",
          icon: "search",
          help_text: "Utilisez des mots-clés pour affiner votre recherche"
        )),
        render(Forms::FieldComponent.new(
          type: "email",
          name: "email_with_icon",
          label: "Adresse email",
          placeholder: "votre@email.com",
          icon: "mail",
          help_text: "Nous ne partagerons jamais votre email"
        )),
        render(Forms::FieldComponent.new(
          type: "password",
          name: "password_with_icon",
          label: "Mot de passe sécurisé",
          placeholder: "••••••••",
          icon: "lock",
          help_text: "Minimum 8 caractères avec majuscules et chiffres"
        ))
      ].join.html_safe
    end
  end
  
  # @label Field Sizes
  def field_sizes
    content_tag :div, class: "space-y-6" do
      [
        content_tag(:div, class: "max-w-sm") do
          [
            content_tag(:h3, "Small", class: "mb-3 font-semibold"),
            render(Forms::FieldComponent.new(
              type: "text",
              name: "small_field",
              label: "Champ petit",
              size: "sm",
              placeholder: "Petit champ"
            ))
          ].join.html_safe
        end,
        content_tag(:div, class: "max-w-md") do
          [
            content_tag(:h3, "Medium (default)", class: "mb-3 font-semibold"),
            render(Forms::FieldComponent.new(
              type: "text",
              name: "medium_field",
              label: "Champ moyen",
              size: "md",
              placeholder: "Champ moyen"
            ))
          ].join.html_safe
        end,
        content_tag(:div, class: "max-w-lg") do
          [
            content_tag(:h3, "Large", class: "mb-3 font-semibold"),
            render(Forms::FieldComponent.new(
              type: "text",
              name: "large_field",
              label: "Champ grand",
              size: "lg",
              placeholder: "Grand champ"
            ))
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
end