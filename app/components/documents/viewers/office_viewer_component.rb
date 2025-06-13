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
        # Use local preview service in development if available
        if document.file.attached?
          if use_local_preview?
            helpers.ged_preview_document_path(document)
          elsif publicly_accessible?
            "https://view.officeapps.live.com/op/embed.aspx?src=#{CGI.escape(document_url)}"
          else
            '#'
          end
        else
          '#'
        end
      end
      
      def use_local_preview?
        # Check if we have a local preview service available
        Rails.env.development? && ENV['DOCUMENT_PROCESSOR_URL'].present?
      end
      
      def publicly_accessible?
        # Check if we have a public URL (e.g., via ngrok or production)
        url_options = Rails.application.config.action_controller.default_url_options
        return false unless url_options.is_a?(Hash)
        
        host = url_options[:host]
        host && !host.include?('localhost') && !host.include?('127.0.0.1')
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
      
      def file_size_human
        return "0 B" unless document.file_size
        
        units = ['B', 'KB', 'MB', 'GB']
        exp = (Math.log(document.file_size) / Math.log(1024)).to_i
        exp = units.length - 1 if exp >= units.length
        
        size = document.file_size.to_f / (1024 ** exp)
        "#{size.round(1)} #{units[exp]}"
      end
    end
  end
end