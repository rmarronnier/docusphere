# frozen_string_literal: true

class Ui::ActionDropdownComponentPreview < ViewComponent::Preview
  # Default icon button dropdown with basic actions
  def default
    actions = [
      {
        label: "Voir",
        href: "/documents/1",
        icon: :eye
      },
      {
        label: "Modifier", 
        href: "/documents/1/edit",
        icon: :edit
      },
      {
        label: "Télécharger",
        href: "/documents/1/download",
        icon: :download
      }
    ]
    
    render Ui::ActionDropdownComponent.new(actions: actions)
  end

  # Button style trigger with text
  def button_trigger
    actions = [
      {
        label: "Créer",
        href: "/documents/new",
        icon: :plus
      },
      {
        label: "Importer",
        href: "/documents/import",
        icon: :upload
      }
    ]
    
    render Ui::ActionDropdownComponent.new(
      actions: actions,
      trigger_style: :button,
      trigger_text: "Actions"
    )
  end

  # Complex dropdown with grouping and danger actions
  def complex_actions
    actions = [
      {
        label: "Télécharger",
        href: "/documents/1/download",
        icon: :download,
        data: { turbo_method: :get }
      },
      {
        label: "Partager",
        action: "share",
        icon: :share,
        data: { action: "click->document-actions#share" }
      },
      { divider: true },
      {
        label: "Dupliquer",
        href: "/documents/1/duplicate",
        icon: :clipboard,
        method: :post,
        confirm: "Dupliquer ce document ?"
      },
      {
        label: "Archiver",
        href: "/documents/1/archive",
        icon: :archive,
        method: :patch,
        confirm: "Archiver ce document ?"
      },
      { divider: true },
      {
        label: "Supprimer",
        href: "/documents/1",
        icon: :trash,
        method: :delete,
        confirm: "Êtes-vous sûr de vouloir supprimer ce document ?",
        danger: true
      }
    ]
    
    render Ui::ActionDropdownComponent.new(
      actions: actions,
      trigger_variant: :secondary
    )
  end

  # Different trigger variants
  def trigger_variants
    actions = [
      { label: "Action 1", href: "/action1", icon: :check },
      { label: "Action 2", href: "/action2", icon: :star }
    ]
    
    content_tag(:div, class: "space-y-4") do
      safe_join([
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Primary: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_style: :button,
              trigger_text: "Primary",
              trigger_variant: :primary
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Secondary: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_style: :button,
              trigger_text: "Secondary",
              trigger_variant: :secondary
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Ghost: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_style: :ghost
            ))
          ])
        end
      ])
    end
  end

  # Different sizes
  def sizes
    actions = [
      { label: "Small Action", href: "/action", icon: :check }
    ]
    
    content_tag(:div, class: "space-y-4") do
      safe_join([
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Extra Small: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_size: :xs
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Small: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_size: :sm
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Medium: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_size: :md
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Large: ", class: "mr-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              trigger_size: :lg
            ))
          ])
        end
      ])
    end
  end

  # Position variations
  def positions
    actions = [
      { label: "Action 1", href: "/action1", icon: :check },
      { label: "Action 2", href: "/action2", icon: :star }
    ]
    
    content_tag(:div, class: "flex justify-between items-center p-8") do
      safe_join([
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Left", class: "block text-sm mb-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              position: "left"
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Center", class: "block text-sm mb-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              position: "center"
            ))
          ])
        end,
        content_tag(:div) do
          safe_join([
            content_tag(:span, "Right", class: "block text-sm mb-2"),
            render(Ui::ActionDropdownComponent.new(
              actions: actions,
              position: "right"
            ))
          ])
        end
      ])
    end
  end

  # JavaScript-only actions
  def javascript_actions
    actions = [
      {
        label: "Show Modal",
        data: { action: "click->modal#show" }
      },
      {
        label: "Copy to Clipboard",
        data: { action: "click->clipboard#copy", clipboard_text: "Hello World!" },
        icon: :clipboard
      },
      {
        label: "Custom Handler",
        data: { action: "click->custom#handle", custom_param: "value" },
        icon: :cog
      }
    ]
    
    render Ui::ActionDropdownComponent.new(
      actions: actions,
      trigger_style: :button,
      trigger_text: "JS Actions"
    )
  end
end