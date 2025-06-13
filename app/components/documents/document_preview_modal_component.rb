# frozen_string_literal: true

module Documents
  class DocumentPreviewModalComponent < ViewComponent::Base
    include ApplicationHelper
    
    def initialize(document:, show_actions: true)
      @document = document
      @show_actions = show_actions
    end

    private

    attr_reader :document, :show_actions

    def preview_component
      case document.content_type_category
      when :pdf
        Documents::Viewers::PdfViewerComponent.new(document: document, show_actions: show_actions)
      when :image
        Documents::Viewers::ImageViewerComponent.new(document: document, show_actions: show_actions)
      when :video
        Documents::Viewers::VideoPlayerComponent.new(document: document, show_actions: show_actions)
      when :office
        Documents::Viewers::OfficeViewerComponent.new(document: document, show_actions: show_actions)
      when :text
        Documents::Viewers::TextViewerComponent.new(document: document, show_actions: show_actions)
      else
        nil
      end
    end

    def has_preview?
      preview_component.present?
    end

    def modal_actions
      actions = []
      
      if show_actions
        actions << {
          label: "Télécharger",
          icon: :arrow_down_tray,
          path: helpers.ged_download_document_path(document),
          css_class: "btn-primary"
        }
        
        if can_open_in_new_tab?
          actions << {
            label: "Ouvrir dans un nouvel onglet",
            icon: :arrow_top_right_on_square,
            path: document_direct_url,
            target: "_blank",
            css_class: "btn-secondary"
          }
        end
        
        if helpers.policy(document).update?
          actions << {
            label: "Modifier",
            icon: :pencil,
            path: helpers.ged_edit_document_path(document),
            css_class: "btn-secondary"
          }
        end
      end
      
      actions
    end

    def file_info
      info = []
      info << "Type: #{document.file_extension&.upcase || 'Unknown'}"
      info << "Taille: #{helpers.number_to_human_size(document.file.byte_size)}" if document.file.attached?
      info << "Modifié: #{document.updated_at.to_fs(:short)}"
      info.join(" • ")
    end

    def document_direct_url
      return '#' unless document.file.attached?
      helpers.rails_blob_url(document.file, disposition: 'inline')
    end

    def can_open_in_new_tab?
      document.pdf? || document.image? || document.text?
    end
    
    def preview_content
      if has_preview?
        render preview_component
      else
        fallback_content
      end
    end
    
    def fallback_content
      content_tag :div, class: "h-full flex items-center justify-center bg-gray-50" do
        content_tag :div, class: "text-center max-w-md" do
          safe_join([
            content_tag(:div, class: "mx-auto w-24 h-24 bg-gray-200 rounded-lg flex items-center justify-center mb-4") do
              render Ui::IconComponent.new(name: :document, size: 12, css_class: "text-gray-400")
            end,
            content_tag(:h3, "Aperçu non disponible", class: "text-lg font-medium text-gray-900 mb-2"),
            content_tag(:p, "Ce type de fichier ne peut pas être prévisualisé. Téléchargez le fichier pour le consulter.", class: "text-sm text-gray-500 mb-6"),
            if show_actions
              link_to helpers.ged_download_document_path(document), 
                      class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors" do
                concat render(Ui::IconComponent.new(name: :arrow_down_tray, size: 5, css_class: "mr-2"))
                concat "Télécharger le fichier"
              end
            end
          ].compact)
        end
      end
    end
    
    def modal_actions_html
      return "" unless modal_actions.any?
      
      safe_join(modal_actions.map do |action|
        link_to action[:path], 
                class: "inline-flex items-center px-3 py-1.5 text-sm font-medium rounded-md #{action[:css_class]}",
                target: action[:target],
                data: { turbo_frame: "_top" } do
          safe_join([
            render(Ui::IconComponent.new(name: action[:icon], size: 4, css_class: "mr-1.5")),
            action[:label]
          ])
        end
      end)
    end
    
    def time_ago_in_words(time)
      helpers.time_ago_in_words(time)
    end
    
    def number_to_human_size(size)
      helpers.number_to_human_size(size)
    end
  end
end