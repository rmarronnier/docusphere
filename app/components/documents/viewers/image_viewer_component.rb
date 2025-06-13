# frozen_string_literal: true

module Documents
  module Viewers
    class ImageViewerComponent < ViewComponent::Base
      include ApplicationHelper
      
      def initialize(document:, show_actions: true)
        @document = document
        @show_actions = show_actions
      end
      
      private
      
      attr_reader :document, :show_actions
      
      def image_url
        if document.file.attached?
          helpers.rails_blob_url(document.file)
        else
          '#'
        end
      end
      
      def has_collection_navigation?
        document.part_of_collection?
      end
      
      def collection_info
        "#{document.collection_index + 1} / #{document.collection_count}"
      end
      
      def download_button
        link_to helpers.ged_download_document_path(document), 
                class: "btn btn-sm btn-secondary",
                data: { turbo_frame: "_top" } do
          concat render(Ui::IconComponent.new(name: :arrow_down_tray, size: 4, css_class: "mr-1"))
          concat "Télécharger"
        end
      end
      
      def icon_button(icon_name, title, options = {})
        button_tag type: "button",
                   class: "p-1 rounded hover:bg-gray-200 transition-colors",
                   title: title,
                   **options do
          render Ui::IconComponent.new(name: icon_name.to_sym, size: 5)
        end
      end
    end
  end
end