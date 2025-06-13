# frozen_string_literal: true

module Documents
  module Viewers
    class OfficeViewerComponent < ViewComponent::Base
      include ApplicationHelper
      
      def initialize(document:, show_actions: true)
        @document = document
        @show_actions = show_actions
      end
      
      private
      
      attr_reader :document, :show_actions
      
      def office_viewer_url
        # Microsoft Office Online Viewer for public documents
        # For private documents, would need different approach
        if document.file.attached?
          "https://view.officeapps.live.com/op/embed.aspx?src=#{CGI.escape(document_url)}"
        else
          '#'
        end
      end
      
      def document_url
        # This would need to be a publicly accessible URL
        # In production, might use a signed URL with expiry
        helpers.rails_blob_url(document.file, host: Rails.application.config.action_controller.default_url_options[:host])
      end
      
      def file_type_name
        case document.file_extension&.downcase
        when 'doc', 'docx' then 'Word Document'
        when 'xls', 'xlsx' then 'Excel Spreadsheet'  
        when 'ppt', 'pptx' then 'PowerPoint Presentation'
        else 'Office Document'
        end
      end
      
      def file_icon
        case document.file_extension&.downcase
        when 'doc', 'docx' then :document_text
        when 'xls', 'xlsx' then :table_cells
        when 'ppt', 'pptx' then :presentation_chart_bar
        else :document
        end
      end
      
      def download_button
        link_to helpers.ged_download_document_path(document), 
                class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors",
                data: { turbo_frame: "_top" } do
          concat render(Ui::IconComponent.new(name: :arrow_down_tray, size: 5, css_class: "mr-2"))
          concat "Télécharger"
        end
      end
      
      def edit_button
        link_to helpers.ged_edit_document_path(document),
                class: "inline-flex items-center px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors" do
          concat render(Ui::IconComponent.new(name: :pencil, size: 5, css_class: "mr-2"))
          concat "Modifier"
        end
      end
    end
  end
end