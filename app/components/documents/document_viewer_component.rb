# frozen_string_literal: true

module Documents
  class DocumentViewerComponent < ViewComponent::Base
    include ApplicationHelper
    
    def initialize(document:, show_actions: true, show_sidebar: true, context: nil)
      @document = document
      @show_actions = show_actions
      @show_sidebar = show_sidebar
      @context = context # Can be :project, :validation, :workflow, etc.
    end

    private

    attr_reader :document, :show_actions, :show_sidebar, :context

    def viewer_content
      viewer_component = case document.content_type_category
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
      when :cad
        cad_viewer # Keep legacy for now
      when :archive
        archive_viewer # Keep legacy for now
      else
        nil
      end
      
      if viewer_component
        render viewer_component
      else
        fallback_viewer
      end
    end

    def cad_viewer
      content_tag(:div, class: "cad-viewer-container h-full") do
        if document.preview.attached?
          # Show CAD preview image
          render Documents::Viewers::ImageViewerComponent.new(document: document, show_actions: show_actions)
        else
          fallback_viewer
        end
      end
    end

    def archive_viewer
      content_tag(:div, class: "archive-viewer-container h-full", data: { controller: "archive-viewer" }) do
        content_tag(:div, class: "archive-contents flex-1 overflow-auto p-4") do
          archive_file_list
        end
      end
    end

    def fallback_viewer
      content_tag(:div, class: "fallback-viewer flex flex-col items-center justify-center h-full p-8 text-center bg-gray-50") do
        concat(document_icon(size: :large))
        concat(content_tag(:h3, document.title, class: "mt-4 text-xl font-semibold text-gray-900"))
        concat(file_info_details)
        concat(content_tag(:p, "Preview not available for this file type", class: "mt-4 text-sm text-gray-600"))
        concat(viewer_actions) if show_actions
      end
    end

    def document_icon(size: :medium)
      icon_size = case size
      when :small then 16
      when :medium then 24
      when :large then 48
      else 24
      end
      
      render Ui::IconComponent.new(
        name: document_icon_name,
        size: icon_size,
        css_class: "text-gray-400"
      )
    end

    def document_icon_name
      case document.content_type_category
      when :pdf then :document_text
      when :image then :photo
      when :video then :video_camera
      when :audio then :musical_note
      when :text then :document_text
      when :spreadsheet then :table_cells
      when :presentation then :presentation_chart_bar
      when :archive then :archive_box
      else :document
      end
    end

    def file_info_details
      content_tag(:div, class: "mt-2 text-sm text-gray-500") do
        concat(content_tag(:p, "#{document.file_extension.upcase} • #{number_to_human_size(document.file_size)}"))
        concat(content_tag(:p, "Uploaded #{time_ago_in_words(document.created_at)} ago", class: "mt-1"))
      end
    end

    def viewer_actions
      # Use the actions dropdown component
      render Documents::DocumentActionsDropdownComponent.new(document: document, current_user: helpers.current_user)
    end

    def contextual_actions
      return unless show_actions
      
      user_profile = helpers.current_user&.active_profile
      return unless user_profile
      
      render Documents::DocumentViewerActionsComponent.new(
        document: document, 
        user_profile: user_profile,
        context: context
      )
    end

    def sidebar_content
      return unless show_sidebar
      
      content_tag(:div, class: "document-sidebar w-80 bg-white border-l", data: { turbo_frame: "document_sidebar" }) do
        concat(document_metadata)
        concat(document_activity) if show_activity?
        concat(related_documents) if show_related?
      end
    end

    def document_metadata
      content_tag(:div, class: "p-4 border-b") do
        concat(content_tag(:h3, "Informations", class: "text-lg font-semibold mb-3"))
        concat(metadata_list)
      end
    end

    def metadata_list
      content_tag(:dl, class: "space-y-2") do
        metadata_items.each do |item|
          concat(metadata_item(item[:label], item[:value]))
        end
      end
    end

    def metadata_items
      items = []
      items << { label: "Type", value: document.content_type_label }
      items << { label: "Taille", value: number_to_human_size(document.file_size) }
      items << { label: "Créé le", value: l(document.created_at, format: :long) }
      items << { label: "Modifié le", value: l(document.updated_at, format: :long) }
      items << { label: "Version", value: document.version_number } if document.respond_to?(:version_number)
      items << { label: "Statut", value: document.status_label } if document.respond_to?(:status_label)
      items
    end

    def metadata_item(label, value)
      content_tag(:div, class: "flex justify-between") do
        concat(content_tag(:dt, label, class: "text-sm font-medium text-gray-500"))
        concat(content_tag(:dd, value, class: "text-sm text-gray-900"))
      end
    end

    def document_activity
      content_tag(:div, class: "p-4 border-b") do
        concat(content_tag(:h3, "Activité récente", class: "text-lg font-semibold mb-3"))
        concat(activity_list)
      end
    end

    def activity_list
      # This would be populated with actual activity data
      content_tag(:div, class: "text-sm text-gray-500") do
        "Aucune activité récente"
      end
    end

    def related_documents
      content_tag(:div, class: "p-4") do
        concat(content_tag(:h3, "Documents liés", class: "text-lg font-semibold mb-3"))
        concat(related_list)
      end
    end

    def related_list
      # This would be populated with actual related documents
      content_tag(:div, class: "text-sm text-gray-500") do
        "Aucun document lié"
      end
    end

    def show_activity?
      context != :minimal
    end

    def show_related?
      context != :minimal && document.respond_to?(:related_documents)
    end

    def archive_file_list
      # Would integrate with a service to list archive contents
      content_tag(:div, class: "text-sm text-gray-600") do
        "Archive preview coming soon..."
      end
    end

    def download_button
      link_to helpers.ged_download_document_path(document), 
              class: "btn btn-sm btn-secondary",
              data: { turbo_frame: "_top" } do
        concat render(Ui::IconComponent.new(name: :arrow_down_tray, size: 4, css_class: "mr-1"))
        concat "Télécharger"
      end
    end

    # Helper method delegations
    def policy(record)
      helpers.policy(record)
    end

    def number_to_human_size(size)
      helpers.number_to_human_size(size)
    end

    def time_ago_in_words(time)
      helpers.time_ago_in_words(time)
    end

    def l(time, format: :default)
      helpers.l(time, format: format)
    end

    def ged_folder_path(folder)
      helpers.ged_folder_path(folder)
    end

    def ged_document_path(document)
      helpers.ged_document_path(document)
    end

    def ged_document_version_path(document, version)
      helpers.ged_document_version_path(document, version)
    end

    def ged_restore_document_version_path(document, version)
      helpers.ged_restore_document_version_path(document, version)
    end

    def heroicon(name, variant: :outline, options: {})
      # Map common heroicon options to IconComponent parameters
      icon_options = {}
      icon_options[:css_class] = options[:class] if options[:class]
      icon_options[:size] = options[:size] || 5
      
      render Ui::IconComponent.new(name: name, **icon_options)
    end
  end
end