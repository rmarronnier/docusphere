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

    def preview_content
      return pdf_viewer if document.pdf?
      return image_viewer if document.image?
      return video_player if document.video?
      return office_viewer if document.office_document?
      return text_viewer if document.text?
      fallback_download_prompt
    end

    def pdf_viewer
      content_tag(:div, class: "pdf-viewer h-full") do
        content_tag(:iframe,
          nil,
          src: pdf_viewer_url,
          class: "w-full h-full border-0 rounded-lg",
          loading: "lazy",
          title: "PDF Viewer: #{document.name}"
        )
      end
    end

    def image_viewer
      content_tag(:div, class: "image-viewer flex items-center justify-center h-full bg-gray-100", data: { controller: "image-zoom" }) do
        image_tag(
          preview_url(:large),
          class: "max-w-full max-h-full object-contain cursor-zoom-in",
          alt: document.name,
          loading: "lazy",
          data: { 
            action: "click->image-zoom#toggle",
            "image-zoom-src-value": preview_url(:original)
          }
        )
      end
    end

    def video_player
      content_tag(:div, class: "video-player h-full flex items-center justify-center bg-black") do
        video_tag(
          rails_blob_path(document.file),
          controls: true,
          class: "max-w-full max-h-full",
          preload: "metadata",
          poster: document.thumbnail_url
        )
      end
    end

    def office_viewer
      if document.preview.attached?
        # If we have a preview image generated from the office document
        image_viewer
      else
        # Fallback to showing document info with download option
        office_fallback_viewer
      end
    end

    def text_viewer
      content_tag(:div, class: "text-viewer h-full overflow-auto bg-gray-50 p-6 rounded-lg") do
        content_tag(:pre, class: "text-sm font-mono whitespace-pre-wrap") do
          # Read first 10KB of text file for preview
          text_content = document.file.download[0..10240]
          text_content.force_encoding('UTF-8').scrub('?')
        end
      end
    end

    def fallback_download_prompt
      content_tag(:div, class: "fallback-viewer flex flex-col items-center justify-center h-full p-8 text-center") do
        concat(icon_for_document)
        concat(content_tag(:h3, "Preview not available", class: "mt-4 text-lg font-semibold text-gray-900"))
        concat(content_tag(:p, "This file type cannot be previewed in the browser", class: "mt-2 text-sm text-gray-600"))
        concat(download_button) if show_actions
      end
    end

    def office_fallback_viewer
      content_tag(:div, class: "office-fallback flex flex-col items-center justify-center h-full p-8") do
        concat(icon_for_document)
        concat(content_tag(:h3, document.name, class: "mt-4 text-lg font-semibold text-gray-900"))
        concat(file_info)
        concat(content_tag(:p, "Office documents require download to view", class: "mt-4 text-sm text-gray-600"))
        concat(download_button) if show_actions
      end
    end

    def modal_actions
      return unless show_actions

      content_tag(:div, class: "modal-actions flex items-center gap-4") do
        concat(download_button)
        concat(open_in_new_tab_button) if can_open_in_new_tab?
        concat(share_button) if policy(document).share?
        concat(edit_button) if policy(document).update?
      end
    end

    def download_button
      link_to(
        ged_download_document_path(document),
        class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors",
        data: { turbo: false }
      ) do
        concat(heroicon("arrow-down-tray", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Download")
      end
    end

    def open_in_new_tab_button
      link_to(
        rails_blob_path(document.file),
        target: "_blank",
        rel: "noopener",
        class: "inline-flex items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
      ) do
        concat(heroicon("arrow-top-right-on-square", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Open in New Tab")
      end
    end

    def share_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors",
        data: { action: "click->document-preview#share" }
      ) do
        concat(heroicon("share", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Share")
      end
    end

    def edit_button
      link_to(
        edit_ged_document_path(document),
        class: "inline-flex items-center px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
      ) do
        concat(heroicon("pencil", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Edit")
      end
    end

    def file_info
      content_tag(:div, class: "file-info mt-2 text-sm text-gray-600") do
        concat("Type: #{document.file_extension&.upcase || 'Unknown'}")
        concat(" • ")
        concat("Size: #{number_to_human_size(document.file.byte_size)}")
        concat(" • ")
        concat("Modified: #{document.updated_at.to_fs(:short)}")
      end
    end

    def icon_for_document
      if document.respond_to?(:icon_for_content_type)
        image_tag(
          document.icon_for_content_type,
          class: "w-24 h-24",
          alt: "File icon"
        )
      else
        content_tag(:div, class: "w-24 h-24 bg-gray-200 rounded-lg flex items-center justify-center") do
          heroicon("document", variant: :solid, options: { class: "w-12 h-12 text-gray-400" })
        end
      end
    end

    def preview_url(variant = :large)
      return asset_path('document-placeholder.png') unless document.file.attached?
      
      if document.respond_to?(:preview_url)
        document.preview_url(variant)
      elsif document.preview.attached?
        rails_blob_path(document.preview)
      elsif document.file.variable?
        rails_representation_path(document.file.variant(resize_to_limit: variant_dimensions(variant)))
      else
        rails_blob_path(document.file)
      end
    end

    def variant_dimensions(variant)
      case variant
      when :thumbnail then [200, 200]
      when :medium then [800, 600]
      when :large then [1200, 900]
      when :original then nil
      else [800, 600]
      end
    end

    def pdf_viewer_url
      # Using browser's built-in PDF viewer for now
      # Later can integrate PDF.js for better control
      rails_blob_path(document.file)
    end

    def document_path(doc)
      helpers.ged_document_path(doc)
    end

    def preview_document_path(doc)
      helpers.ged_document_preview_path(doc) if helpers.respond_to?(:ged_document_preview_path)
    end

    def ged_download_document_path(doc)
      helpers.ged_download_document_path(doc)
    end

    def ged_document_path(doc)
      helpers.ged_document_path(doc)
    end

    def edit_ged_document_path(doc)
      helpers.ged_edit_document_path(doc)
    end

    def time_ago_in_words(time)
      helpers.time_ago_in_words(time)
    end

    def can_open_in_new_tab?
      document.pdf? || document.image? || document.text?
    end

    def policy(record)
      helpers.policy(record)
    end

    def heroicon(name, variant: :outline, options: {})
      helpers.heroicon(name, variant: variant, options: options)
    end

    def rails_blob_path(attachment)
      helpers.rails_blob_path(attachment)
    end

    def rails_representation_path(variant)
      helpers.rails_representation_path(variant)
    end

    def number_to_human_size(size)
      helpers.number_to_human_size(size)
    end
  end
end