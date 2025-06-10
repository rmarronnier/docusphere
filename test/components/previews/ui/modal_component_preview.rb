# @label Modal Component
class Ui::ModalComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Modal
  def default
    content_tag :div do
      safe_join([
        button_to_open_modal("Ouvrir la modal", "modal-default"),
        
        render(Ui::ModalComponent.new(
          id: "modal-default",
          title: "Titre de la modal"
        )) do
          content_tag :p, "Contenu de la modal. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        end
      ])
    end
  end
  
  # @label Sizes
  def sizes
    content_tag :div, class: "space-x-2" do
      safe_join([
        button_to_open_modal("Small", "modal-sm"),
        button_to_open_modal("Medium", "modal-md"),
        button_to_open_modal("Large", "modal-lg"),
        button_to_open_modal("Extra Large", "modal-xl"),
        
        render(Ui::ModalComponent.new(id: "modal-sm", title: "Small Modal", size: :sm)) do
          content_tag :p, "Contenu d'une petite modal."
        end,
        
        render(Ui::ModalComponent.new(id: "modal-md", title: "Medium Modal", size: :md)) do
          content_tag :p, "Contenu d'une modal moyenne (taille par défaut)."
        end,
        
        render(Ui::ModalComponent.new(id: "modal-lg", title: "Large Modal", size: :lg)) do
          content_tag :p, "Contenu d'une grande modal avec plus d'espace."
        end,
        
        render(Ui::ModalComponent.new(id: "modal-xl", title: "Extra Large Modal", size: :xl)) do
          content_tag :p, "Contenu d'une très grande modal pour des formulaires complexes."
        end
      ])
    end
  end
  
  # @label With Footer
  def with_footer
    content_tag :div do
      safe_join([
        button_to_open_modal("Modal avec footer", "modal-footer"),
        
        render(Ui::ModalComponent.new(id: "modal-footer", title: "Confirmer l'action")) do |modal|
          modal.with_body do
            content_tag :p, "Êtes-vous sûr de vouloir effectuer cette action ? Cette opération est irréversible."
          end
          
          modal.with_footer do
            content_tag :div, class: "flex justify-end space-x-2" do
              safe_join([
                button_tag("Annuler", type: "button", class: "btn btn-secondary", data: { action: "click->modal#close" }),
                button_tag("Confirmer", type: "button", class: "btn btn-danger")
              ])
            end
          end
        end
      ])
    end
  end
  
  # @label Form Modal
  def form_modal
    content_tag :div do
      safe_join([
        button_to_open_modal("Nouveau document", "modal-form"),
        
        render(Ui::ModalComponent.new(id: "modal-form", title: "Créer un nouveau document")) do |modal|
          modal.with_body do
            form_tag "#", class: "space-y-4" do
              safe_join([
                content_tag(:div) do
                  safe_join([
                    label_tag(:title, "Titre", class: "block text-sm font-medium text-gray-700 mb-1"),
                    text_field_tag(:title, nil, class: "form-input w-full", placeholder: "Entrez le titre du document")
                  ])
                end,
                
                content_tag(:div) do
                  safe_join([
                    label_tag(:description, "Description", class: "block text-sm font-medium text-gray-700 mb-1"),
                    text_area_tag(:description, nil, class: "form-textarea w-full", rows: 3, placeholder: "Description du document")
                  ])
                end,
                
                content_tag(:div) do
                  safe_join([
                    label_tag(:file, "Fichier", class: "block text-sm font-medium text-gray-700 mb-1"),
                    file_field_tag(:file, class: "form-input w-full")
                  ])
                end
              ])
            end
          end
          
          modal.with_footer do
            content_tag :div, class: "flex justify-end space-x-2" do
              safe_join([
                button_tag("Annuler", type: "button", class: "btn btn-secondary", data: { action: "click->modal#close" }),
                button_tag("Créer", type: "submit", class: "btn btn-primary")
              ])
            end
          end
        end
      ])
    end
  end
  
  # @label Scrollable Content
  def scrollable
    content_tag :div do
      safe_join([
        button_to_open_modal("Modal avec contenu long", "modal-scroll"),
        
        render(Ui::ModalComponent.new(id: "modal-scroll", title: "Conditions d'utilisation", size: :lg)) do |modal|
          modal.with_body do
            content_tag :div, class: "prose max-w-none" do
              safe_join([
                content_tag(:h3, "1. Introduction"),
                content_tag(:p, lorem_paragraph),
                content_tag(:h3, "2. Acceptation des conditions"),
                content_tag(:p, lorem_paragraph),
                content_tag(:h3, "3. Utilisation du service"),
                content_tag(:p, lorem_paragraph),
                content_tag(:h3, "4. Propriété intellectuelle"),
                content_tag(:p, lorem_paragraph),
                content_tag(:h3, "5. Limitation de responsabilité"),
                content_tag(:p, lorem_paragraph),
                content_tag(:h3, "6. Modifications"),
                content_tag(:p, lorem_paragraph)
              ])
            end
          end
          
          modal.with_footer do
            content_tag :div, class: "flex justify-end space-x-2" do
              safe_join([
                button_tag("Refuser", type: "button", class: "btn btn-secondary", data: { action: "click->modal#close" }),
                button_tag("Accepter", type: "button", class: "btn btn-primary")
              ])
            end
          end
        end
      ])
    end
  end
  
  # @label Without Close Button
  def no_close_button
    content_tag :div do
      safe_join([
        button_to_open_modal("Modal sans bouton fermer", "modal-no-close"),
        
        render(Ui::ModalComponent.new(
          id: "modal-no-close",
          title: "Traitement en cours",
          closable: false
        )) do |modal|
          modal.with_body do
            content_tag :div, class: "text-center py-8" do
              safe_join([
                content_tag(:div, class: "animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto mb-4"),
                content_tag(:p, "Veuillez patienter pendant le traitement...", class: "text-gray-600")
              ])
            end
          end
        end
      ])
    end
  end
  
  private
  
  def button_to_open_modal(label, modal_id)
    button_tag(label, 
      type: "button", 
      class: "btn btn-primary",
      data: { 
        controller: "modal",
        action: "click->modal#open",
        modal_target_value: modal_id
      }
    )
  end
  
  def lorem_paragraph
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
  end
end