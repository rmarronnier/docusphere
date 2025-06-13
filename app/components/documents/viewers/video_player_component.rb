# frozen_string_literal: true

module Documents
  module Viewers
    class VideoPlayerComponent < ViewComponent::Base
      include ApplicationHelper
      
      def initialize(document:, show_actions: true)
        @document = document
        @show_actions = show_actions
      end
      
      private
      
      attr_reader :document, :show_actions
      
      def video_url
        if document.file.attached?
          helpers.rails_blob_url(document.file)
        else
          '#'
        end
      end
      
      def video_poster
        if document.thumbnail.attached?
          helpers.rails_blob_url(document.thumbnail)
        else
          nil
        end
      end
      
      def video_type
        document.file.blob.content_type if document.file.attached?
      end
      
      def download_button
        link_to helpers.ged_download_document_path(document), 
                class: "btn btn-sm btn-secondary ml-2",
                data: { turbo_frame: "_top" } do
          concat render(Ui::IconComponent.new(name: :arrow_down_tray, size: 4, css_class: "mr-1"))
          concat "Télécharger"
        end
      end
    end
  end
end